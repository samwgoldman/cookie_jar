require "cookie"

class CookieJar
  def initialize
    @cookies = []
  end

  def set_cookie(request_uri, cookie_string)
    cookie = Cookie.parse(request_uri, cookie_string)
    existing_cookie = @cookies.find { |c| c.matches?(cookie) }
    @cookies.delete(existing_cookie) if existing_cookie
    @cookies << cookie unless cookie.expired?
  end

  def cookie
    @cookies.map { |cookie| "#{cookie.name}=#{cookie.value}" }.join("; ")
  end
end
