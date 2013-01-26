require "cookie_jar"

describe CookieJar do
  it "stores cookies" do
    jar = CookieJar.new
    jar.set_cookie("SID=31d4d96e407aad42")
    jar.cookie.should eq("SID=31d4d96e407aad42")
  end
end
