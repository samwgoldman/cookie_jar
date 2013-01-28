require "cookie"
require "ostruct"
require "uri"

describe Cookie do
  let(:request_uri) { URI.parse("http://example.com") }
  it "has value semantics" do
    a = Cookie.new("SID", "31d4d96e407aad42", "Domain" => "example.com")
    b = Cookie.new("SID", "31d4d96e407aad42", "Domain" => "example.com")

    a.should eq(b)
    a.should eql(b)
    a.hash.should eql(b.hash)
  end

  it "can parse a Set-Cookie header value" do
    cookie = Cookie.parse(request_uri, "SID=31d4d96e407aad42; Path=/; Secure; HttpOnly")
    cookie.name.should eq("SID")
    cookie.value.should eq("31d4d96e407aad42")
    cookie.path.should eq("/")
    cookie.should be_secure
    cookie.should be_http_only
  end

  it "ignores the set-cookie-string if it lacks a = character in the name-value pair" do
    expect {
      Cookie.parse(request_uri, "SID31d4d96e407aad42; Path=/; Secure; HttpOnly")
    }.to raise_error(Cookie::InvalidCookie, "incomplete name-value pair")
  end

  it "removes any leading or trailing white space from the name string and value string" do
    cookie = Cookie.parse(request_uri, " SID\t=\t31d4d96e407aad42 ")
    cookie.name.should eq("SID")
    cookie.value.should eq("31d4d96e407aad42")
  end

  it "ignores the set-cookie-string if the name string is empty" do
    expect {
      cookie = Cookie.parse(request_uri, "=31d4d96e407aad42")
    }.to raise_error(Cookie::InvalidCookie, "name string is empty")
  end

  it "removes any leading or trailing white space from the attribute-name string and attribute-value string" do
    cookie = Cookie.parse(request_uri, "SID=31d4d96e407aad42; Path\t= /\t; Secure\t")
    cookie.path.should eq("/")
    cookie.should be_secure
  end

  it "is expired if the Expires attribute-value is in the past" do
    cookie = Cookie.parse(request_uri, "lang=en-US; Expires=Sun, 06 Nov 1994 08:49:37 GMT")
    cookie.should be_expired
  end

  it "case-insensitively matches the Expires attribute-name" do
    cookie = Cookie.parse(request_uri, "lang=en-US; eXpIrEs=Sun, 06 Nov 1994 08:49:37 GMT")
    cookie.should be_expired
  end

  it "does not expire if no Expires attribute-value is set" do
    cookie = Cookie.parse(request_uri, "SID=31d4d96e407aad42; Path=/; Secure; HttpOnly")
    cookie.should_not be_expired
  end

  it "does not expire if the Expires attribute-value fails to parse" do
    cookie = Cookie.parse(request_uri, "lang=en-US; Expires=ABCDEFG")
    cookie.should_not be_expired
  end

  it "is expired if the Max-Age attribute-value has passed since the cookie was created" do
    now = Time.now - 60
    cookie = Cookie.parse(request_uri, "lang=en-US; Max-Age=60", now)
    cookie.should be_expired
  end

  it "is not expired if the Max-Age attribute-value has not yet passed" do
    now = Time.now - 60
    cookie = Cookie.parse(request_uri, "lang=en-US; Max-Age=61", now)
    cookie.should_not be_expired
  end

  it "case-insensitively matches the Max-Age attribute name" do
    now = Time.now - 60
    cookie = Cookie.parse(request_uri, "lang=en-US; mAx-AgE=60", now)
    cookie.should be_expired
  end

  it "is expired if the Max-Age attribute value is 0" do
    cookie = Cookie.parse(request_uri, "lang=en-US; Max-Age=0")
    cookie.should be_expired
  end

  it "is expired if the Max-Age attribute value is less than 0" do
    cookie = Cookie.parse(request_uri, "lang=en-US; Max-Age=-1")
    cookie.should be_expired
  end

  it "is not expired if the Max-Age attribute contains a non-digit character" do
    now = Time.now - 60
    cookie = Cookie.parse(request_uri, "lang=en-US; Max-Age=59s", now)
    cookie.should_not be_expired
  end

  it "gives precedence to the Max-Age attribute over the Expires attribute" do
    now = Time.now - 60
    cookie = Cookie.parse(request_uri, "lang=en-US; Expires=Sun, 06 Nov 1994 08:49:37 GMT; Max-Age=61", now)
    cookie.should_not be_expired
  end

  it "exposes the Domain gttribute-value" do
    cookie = Cookie.parse(request_uri, "lang=en-US; Domain=example.com")
    cookie.domain.should eq("example.com")
  end

  it "case-insensitively matches the Domain attribute-name" do
    cookie = Cookie.parse(request_uri, "lang=en-US; dOmAiN=example.com")
    cookie.domain.should eq("example.com")
  end

  it "ignores the leading character of the Domain attribute-value, if it is a period (.)" do
    cookie = Cookie.parse(request_uri, "lang=en-US; Domain=.example.com")
    cookie.domain.should eq("example.com")
  end

  it "converts the Domain attribute-value to lowercase" do
    cookie = Cookie.parse(request_uri, "lang=en-US; Domain=eXaMpLe.cOm")
    cookie.domain.should eq("example.com")
  end

  it "ignores the set-cookie-string if the request host does not match the Domain attribute-value" do
    request_uri = URI.parse("http://example.com")
    expect {
      Cookie.parse(request_uri, "lang=en-US; Domain=ietf.org")
    }.to raise_error(Cookie::InvalidCookie, "cookie domain does not match the request host")
  end

  it "uses the request host as the cookie domain if the Domain attribute-value is empty" do
    request_uri = URI.parse("http://example.com")
    cookie = Cookie.parse(request_uri, "lang=en-US")
    cookie.domain.should eq("example.com")
  end

  it "uses the default path as the cookie path if the Path attribute-value is missing" do
    request_uri = URI.parse("http://example.com/foo/bar?baz")
    cookie = Cookie.parse(request_uri, "lang=en-US")
    cookie.path.should eq("/foo")
  end

  it "uses the default path as the cookie path if the Path attribute-value is empty" do
    request_uri = URI.parse("http://example.com/foo/bar?baz")
    cookie = Cookie.parse(request_uri, "lang=en-US; Path=")
    cookie.path.should eq("/foo")
  end

  it "uses the default path as the cookie path if the Path attribute-value does not start with a slash (/)" do
    request_uri = URI.parse("http://example.com/foo/bar?baz")
    cookie = Cookie.parse(request_uri, "lang=en-US; Path=foobar")
    cookie.path.should eq("/foo")
  end

  it "uses a default path of slash (/) if the Path attribute-value is missing and the uri-path is empty" do
    request_uri = URI.parse("http://example.com")
    cookie = Cookie.parse(request_uri, "lang=en-US; Path=foobar")
    cookie.path.should eq("/")
  end

  it "uses a default path of slash (/) if the uri-path contains no more than one slash (/)" do
    request_uri = URI.parse("http://example.com/foobar")
    cookie = Cookie.parse(request_uri, "lang=en-US; Path=foobar")
    cookie.path.should eq("/")
  end

  it "uses the uri-path up to, but not including the right-most slash (/)" do
    request_uri = URI.parse("http://example.com/foo/bar")
    cookie = Cookie.parse(request_uri, "lang=en-US; Path=foobar")
    cookie.path.should eq("/foo")
  end

  it "uses a default path of slash (/) if the Path attribute-value is missing and the uri-path does not start with slash (/)" do
    request_uri = OpenStruct.new(:scheme => "http", :host => "example.com", :path => "foobar")
    cookie = Cookie.parse(request_uri, "lang=en-US; Path=foobar")
    cookie.path.should eq("/")
  end

  it "ignores the set-cookie-string if the request uri is non-HTTP and http-only-flag is set" do
    request_uri = URI.parse("ftp://example.com")
    expect {
      Cookie.parse(request_uri, "lang=en-US; HttpOnly")
    }.to raise_error(Cookie::InvalidCookie, "HTTP only cookie received from non-HTTP API")
  end

  it "allows HttpOnly cookies from HTTPS APIs" do
    request_uri = URI.parse("https://example.com")
    expect {
      Cookie.parse(request_uri, "lang=en-US; HttpOnly")
    }.not_to raise_error
  end

  it "uses the last Max-Age attribute if there are multiple" do
    now = Time.now - 60
    cookie = Cookie.parse(request_uri, "lang=en-US; Max-Age=61; Max-Age=60", now)
    cookie.should be_expired
  end

  it "uses the last Expires attribute if there are multiple" do
    now = Time.gm(1994, "Nov", 6, 8, 49, 38)
    cookie = Cookie.parse(request_uri, "lang=en-US; Expires=Sun, 06 Nov 1994 08:49:39 GMT; Expires=Sun, 06 Nov 1994 08:49:37 GMT")
    cookie.should be_expired(now)
  end

  it "uses the last Domain attribute if there are multiple" do
    request_uri = URI.parse("http://example.com")
    cookie = Cookie.parse(request_uri, "lang=en-US; Domain=ietf.org; Domain=example.com")
    cookie.domain.should eq("example.com")
  end

  it "uses the last Path attribute if there are multiple" do
    cookie = Cookie.parse(request_uri, "lang=en-US; Path=/foo/bar; Path=/baz/quux")
    cookie.path.should eq("/baz/quux")
  end
end
