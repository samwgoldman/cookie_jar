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
end
