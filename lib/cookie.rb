require "time"

class Cookie
  InvalidCookie = Class.new(Exception)

  attr_reader :name, :value, :attributes
  protected :attributes

  def initialize(name, value, attributes = {}, now = Time.now)
    @name = name
    @value = value
    @attributes = attributes
    @created_at = now
  end

  def self.parse(cookie_string, now = Time.now)
    (name, value), *attributes = cookie_string.split("; ").map { |part| part.split("=") }
    raise InvalidCookie.new("incomplete name-value pair") if value.nil?
    name.strip!
    value.strip!
    raise InvalidCookie.new("name string is empty") if name.empty?
    attributes.each do |key, value|
      key.strip!
      key.downcase!
      value.strip! unless value.nil?
    end
    new(name, value, Hash[attributes], now)
  end

  def domain
    if attributes.key?("domain")
      attributes["domain"].sub(/\A\./, "").downcase
    end
  end

  def path
    attributes["path"]
  end

  def expired?(now = Time.now)
    expiry_time && expiry_time < now
  end

  def secure?
    attributes.key?("secure")
  end

  def http_only?
    attributes.key?("httponly")
  end

  def ==(other)
    name == other.name && value == other.value && attributes == other.attributes
  end

  def eql?(other)
    name.eql?(other.name) && value.eql?(other.value) && attributes.eql?(other.attributes)
  end

  def hash
    [name, value, attributes].hash
  end

  private

  def expiry_time
    if attributes.key?("max-age")
      seconds = attributes["max-age"].to_i
      if seconds.to_s == attributes["max-age"]
        @created_at + attributes["max-age"].to_i
      end
    elsif attributes.key?("expires")
      Time.parse(attributes["expires"]) rescue nil
    end
  end
end
