require "cookie"

class CookieJar
  def initialize
    @cookies = []
  end

  def set_cookie(cookie_string)
    cookie = Cookie.parse(cookie_string)
    existing_cookie = @cookies.find { |c| c.name == cookie.name }
    if existing_cookie && cookie.expired?
      @cookies.delete(existing_cookie)
    else
      @cookies << cookie
    end
  end

  def cookie
    @cookies.map { |cookie| "#{cookie.name}=#{cookie.value}" }.join("; ")
  end
end
