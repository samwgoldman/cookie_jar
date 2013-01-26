class Cookie
  attr_reader :name, :value, :attributes

  def initialize(name, value, attributes = {})
    @name = name
    @value = value
    @attributes = attributes
  end

  # FIXME: §4.1.1 compliance
  def self.parse(cookie_string)
    (name, value), *attributes = cookie_string.split("; ").map { |part| part.split("=") }
    new(name, value, Hash[attributes])
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
end
