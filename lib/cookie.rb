require "time"

class Cookie
  InvalidCookie = Class.new(Exception)

  attr_reader :name, :value, :attributes

  def initialize(name, value, attributes = {})
    @name = name
    @value = value
    @attributes = attributes
  end

  def self.parse(cookie_string)
    (name, value), *attributes = cookie_string.split("; ").map { |part| part.split("=") }
    raise InvalidCookie.new("incomplete name-value pair") if value.nil?
    name.strip!
    value.strip!
    raise InvalidCookie.new("name string is empty") if name.empty?
    attributes.each do |key, value|
      key.strip!
      value.strip! unless value.nil?
    end
    new(name, value, Hash[attributes])
  end

  def expired?(now = Time.now)
    expiry_time && expiry_time < now
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
    if attributes.key?("Expires")
      Time.parse(attributes["Expires"])
    end
  end
end
