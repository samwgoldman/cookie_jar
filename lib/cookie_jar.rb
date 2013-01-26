class CookieJar
  def set_cookie(cookie)
    @cookie = cookie
  end

  def cookie
    @cookie.split(";").first
  end
end
