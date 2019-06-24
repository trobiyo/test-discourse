# frozen_string_literal: true

module SiteSettings; end

# A cache for providing default value based on site locale
class SiteSettings::DefaultsProvider
  DEFAULT_LOCALE = 'en_US'

  def initialize(site_setting)
    print site_setting.to_s
    @site_setting = site_setting
    @defaults = {}
    @defaults[DEFAULT_LOCALE.to_sym] = {}
  end

  def load_setting(name_arg, value, locale_defaults)    
    puts "Loading Settings..."
    #puts caller
    puts "name_arg: " + name_arg.to_s + " || value: "+ value.to_s + " || locale_defaults: " + locale_defaults.to_s
    name = name_arg.to_sym
    @defaults[DEFAULT_LOCALE.to_sym][name] = value

    if (locale_defaults)
      locale_defaults.each do |locale, v|
        locale = locale.to_sym
        @defaults[locale] ||= {}
        @defaults[locale][name] = v
      end
    end
  end

  def db_all
    @site_setting.provider.all
  end

  def all(locale = nil)
    puts "def all: " + locale.to_s
    if locale
      @defaults[DEFAULT_LOCALE.to_sym].merge(@defaults[locale.to_sym] || {})
    else
      @defaults[DEFAULT_LOCALE.to_sym].dup
    end
  end

  def get(name, locale = DEFAULT_LOCALE)
    value = @defaults.dig(locale.to_sym, name.to_sym)    
    puts "Name: " + name.to_s + "|| Value from DB: " + value.to_s
    return value unless value.nil?

    @defaults.dig(DEFAULT_LOCALE.to_sym, name.to_sym)
  end
  alias [] get

  # Used to override site settings in dev/test env
  def set_regardless_of_locale(name, value)
    name = name.to_sym
    if name == :default_locale || @site_setting.has_setting?(name)
      @defaults.each { |_, hash| hash.delete(name) }
      @defaults[DEFAULT_LOCALE.to_sym][name] = value
      value, type = @site_setting.type_supervisor.to_db_value(name, value)
      @defaults[SiteSetting.default_locale.to_sym] ||= {}
      @defaults[SiteSetting.default_locale.to_sym][name] = @site_setting.type_supervisor.to_rb_value(name, value, type)
    else
      raise ArgumentError.new("No setting named '#{name}' exists")
    end
  end

  def has_setting?(name)
    has_key?(name.to_sym) || has_key?("#{name.to_s}?".to_sym) || name.to_sym == :default_locale
  end

  private

  def has_key?(name)
    @defaults[DEFAULT_LOCALE.to_sym].key?(name)
  end

  def current_db
    RailsMultisite::ConnectionManagement.current_db
  end

end
