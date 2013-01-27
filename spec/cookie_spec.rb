require "cookie"

describe Cookie do
  it "has value semantics" do
    a = Cookie.new("SID", "31d4d96e407aad42", "Domain" => "example.com")
    b = Cookie.new("SID", "31d4d96e407aad42", "Domain" => "example.com")

    a.should eq(b)
    a.should eql(b)
    a.hash.should eql(b.hash)
  end

  it "can parse a Set-Cookie header value" do
    cookie = Cookie.parse("SID=31d4d96e407aad42; Path=/; Secure; HttpOnly")
    cookie.name.should eq("SID")
    cookie.value.should eq("31d4d96e407aad42")
    cookie.attributes.should eq("Path" => "/", "Secure" => nil, "HttpOnly" => nil)
  end

  it "ignores the set-cookie-string if it lacks a = character in the name-value pair" do
    expect {
      Cookie.parse("SID31d4d96e407aad42; Path=/; Secure; HttpOnly")
    }.to raise_error(Cookie::InvalidCookie, "incomplete name-value pair")
  end

  it "removes any leading or trailing white space from the name string and value string" do
    cookie = Cookie.parse(" SID\t=\t31d4d96e407aad42 ")
    cookie.name.should eq("SID")
    cookie.value.should eq("31d4d96e407aad42")
  end

  it "ignores the set-cookie-string if the name string is empty" do
    expect {
      cookie = Cookie.parse("=31d4d96e407aad42")
    }.to raise_error(Cookie::InvalidCookie, "name string is empty")
  end

  it "removes any leading or trailing white space from the attribute-name string and attribute-value string" do
    cookie = Cookie.parse("SID=31d4d96e407aad42; Path\t= /\t; Secure\t")
    cookie.attributes.should eq("Path" => "/", "Secure" => nil)
  end

  it "is expired if the expiry time is in the past" do
    cookie = Cookie.parse("lang=en-US; Expires=Sun, 06 Nov 1994 08:49:37 GMT")
    cookie.should be_expired
  end

  it "does not expire if no expiry time is set" do
    cookie = Cookie.parse("SID=31d4d96e407aad42; Path=/; Secure; HttpOnly")
    cookie.should_not be_expired
  end
end
