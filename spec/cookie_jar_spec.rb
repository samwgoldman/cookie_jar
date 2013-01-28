require "cookie_jar"
require "uri"

describe CookieJar do
  let(:request_uri) { URI.parse("http://example.com") }
  let(:jar) { CookieJar.new }

  it "stores cookies" do
    jar.set_cookie(request_uri, "SID=31d4d96e407aad42")
    jar.cookie.should eq("SID=31d4d96e407aad42")
  end

  it "scopes cookies" do
    jar.set_cookie(request_uri, "SID=31d4d96e407aad42; Path=/; Domain=example.com")
    jar.cookie.should eq("SID=31d4d96e407aad42")
  end

  it "stores multiple cookies" do
    jar.set_cookie(request_uri, "SID=31d4d96e407aad42; Path=/; Secure; HttpOnly")
    jar.set_cookie(request_uri, "lang=en-US; Path=/; Domain=example.com")
    jar.cookie.should eq("SID=31d4d96e407aad42; lang=en-US")
  end

  it "does not replace HTTP-only cookies with cookies from a non-HTTP API" do
    jar.set_cookie(URI.parse("http://example.com"), "lang=en-US; HttpOnly")
    jar.set_cookie(URI.parse("ftp://example.com"), "lang=en-GB")
    jar.cookie.should eq("lang=en-US")
  end

  it "evicts expired cookies" do
    now = Time.now
    later = now + 31
    jar.set_cookie(request_uri, "lang=en-US; Max-Age=30", now)
    jar.cookie(later).should eq("")
  end

  context "with a couple cookies" do
    let(:now) { Time.now - 60 }

    before do
      jar.set_cookie(request_uri, "SID=31d4d96e407aad42; Path=/; Secure; HttpOnly", now)
      jar.set_cookie(request_uri, "lang=en-US; Path=/; Domain=example.com; Max-Age=90", now)
    end

    it "contains at most one cookie with the same name, domain, and path" do
      jar.set_cookie(request_uri, "lang=en-GB; Path=/; Domain=example.com")
      jar.cookie.should eq("SID=31d4d96e407aad42; lang=en-GB")
    end

    it "keeps the same creation time when replaced with a matching cookie" do
      jar.set_cookie(request_uri, "lang=en-US; Path=/; Domain=example.com; Max-Age=30", now)
      jar.cookie.should eq("SID=31d4d96e407aad42")
    end

    it "removes cookies if set to expire in the past" do
      jar.set_cookie(request_uri, "lang=en-US; Expires=Sun, 06 Nov 1994 08:49:37 GMT")
      jar.cookie.should eq("SID=31d4d96e407aad42")
    end
  end
end
