require "cookie"

class CookieJar
  def initialize
    @cookies = []
  end

  def set_cookie(request_uri, cookie_string, now = Time.now)
    begin
      cookie = Cookie.parse(request_uri, cookie_string, now)
    rescue Cookie::InvalidCookie
      return
    end
    existing_cookie = @cookies.find { |c| c.matches?(cookie) }
    if existing_cookie
      @cookies.delete(existing_cookie)
      begin
        cookie = existing_cookie.replace(request_uri, cookie)
      rescue Cookie::InvalidCookie
        cookie = existing_cookie
      end
    end
    @cookies << cookie unless cookie.expired?
  end

  def cookie(now = Time.now)
    @cookies.reject! { |cookie| cookie.expired?(now) }
    @cookies.map { |cookie| "#{cookie.name}=#{cookie.value}" }.join("; ")
  end
end
