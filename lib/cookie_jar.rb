require "cookie"

class CookieJar
  def initialize
    @cookies = []
  end

  def set_cookie(request_uri, cookie_string, now = Time.now)
    cookie = Cookie.parse(request_uri, cookie_string, now)
    existing_cookie = @cookies.find { |c| c.matches?(cookie) }
    if existing_cookie
      @cookies.delete(existing_cookie)
      cookie = existing_cookie.replace(cookie)
    end
    @cookies << cookie unless cookie.expired?
  end

  def cookie
    @cookies.map { |cookie| "#{cookie.name}=#{cookie.value}" }.join("; ")
  end
end
