class CookieJar
  def initialize
    @cookies = []
  end

  def set_cookie(cookie)
    @cookies << cookie
  end

  def cookie
    @cookies.map { |cookie| cookie.split(";").first }.join("; ")
  end
end
