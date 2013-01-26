require "cookie_jar"

describe CookieJar do
  let(:jar) { CookieJar.new }

  it "stores cookies" do
    jar.set_cookie("SID=31d4d96e407aad42")
    jar.cookie.should eq("SID=31d4d96e407aad42")
  end

  it "scopes cookies" do
    jar.set_cookie("SID=31d4d96e407aad42; Path=/; Domain=example.com")
    jar.cookie.should eq("SID=31d4d96e407aad42")
  end

  it "stores multiple cookies" do
    jar.set_cookie("SID=31d4d96e407aad42; Path=/; Secure; HttpOnly")
    jar.set_cookie("lang=en-US; Path=/; Domain=example.com")
    jar.cookie.should eq("SID=31d4d96e407aad42; lang=en-US")
  end

  context "with a couple cookies" do
    before do
      jar.set_cookie("SID=31d4d96e407aad42; Path=/; Secure; HttpOnly")
      jar.set_cookie("lang=en-US; Path=/; Domain=example.com")
    end

    it "removes cookies if set to expire in the past" do
      jar.set_cookie("lang=en-US; Expires=Sun, 06 Nov 1994 08:49:37 GMT")
      jar.cookie.should eq("SID=31d4d96e407aad42")
    end
  end
end
