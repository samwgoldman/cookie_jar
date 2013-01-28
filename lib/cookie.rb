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

  def self.parse(request_uri, cookie_string, now = Time.now)
    (name, value), *attributes = cookie_string.split("; ").map { |part| part.split("=") }
    name = name.strip
    value = value.to_s.strip
    raise InvalidCookie.new("name string is empty") if name.empty?
    raise InvalidCookie.new("incomplete name-value pair") if value.empty?
    attributes.map! { |key, value| [key.strip.downcase, value.to_s.strip] }
    attributes = Hash[attributes]
    if attributes.key?("domain")
      if attributes["domain"].empty?
        raise InvalidCookie.new("cookie domain is empty")
      else
        attributes["domain"].sub!(/\A\./, "")
        attributes["domain"].downcase!
      end
    else
      attributes["domain"] = request_uri.host
    end
    if !attributes.key?("path") || attributes["path"].empty? || attributes["path"][0] != "/"
      if request_uri.path.empty? || request_uri.path[0] != "/"
        attributes["path"] = "/"
      else
        default_path = request_uri.path.split("/")[0..-2].join("/")
        if default_path.empty?
          attributes["path"] = "/"
        else
          attributes["path"] = default_path
        end
      end
    end
    if attributes.key?("domain") && attributes["domain"] != request_uri.host
      raise InvalidCookie.new("cookie domain does not match the request host")
    end
    if attributes.key?("httponly") && request_uri.scheme !~ /\Ahttps?\Z/
      raise InvalidCookie.new("HTTP only cookie received from non-HTTP API")
    end
    new(name, value, attributes, now)
  end

  def domain
    attributes["domain"]
  end

  def path
    attributes["path"]
  end

  def replace(new_cookie)
    Cookie.new(name, new_cookie.value, new_cookie.attributes, @created_at)
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

  def matches?(other)
    name == other.name && domain == other.domain && path == other.path
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
