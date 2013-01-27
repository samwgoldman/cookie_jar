require "cookie"
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

  it "does not have a domain if the Domain attribute is missing" do
    cookie = Cookie.parse(request_uri, "lang=en-US")
    cookie.domain.should be_nil
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
end
