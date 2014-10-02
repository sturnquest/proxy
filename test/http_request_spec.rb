require 'app/http_request'

describe HttpRequest do

  it "parses headers correctly" do
    content = <<-eos
      GET / HTTP/1.1
Host: localhost:2000
Connection: keep-alive
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.124 Safari/537.36
Accept-Encoding: gzip,deflate,sdch
Accept-Language: en-US,en;q=0.8
Cookie: ki_u=e5f4f3e2-9cef-77e5-0663-de412631acf2; ki_s=99406%3A2.1.0.0.2%3B99411%3A142.0.0.1.2%3B99415%3A126.0.0.1.2; ki_t=1355727898352%3B1372970308875%3B1372970308875%3B60%3B685

    eos

    stream = StringIO.new(content)

    request = HttpRequest.build(stream)
    expect(request.headers).to(eq({'Host' => 'localhost:2000', 'Connection' => 'keep-alive',
                                   'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
                                   'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.124 Safari/537.36',
                                   'Accept-Encoding' => 'gzip,deflate,sdch', 'Accept-Language' => 'en-US,en;q=0.8',
                                   'Cookie' => 'ki_u=e5f4f3e2-9cef-77e5-0663-de412631acf2; ki_s=99406%3A2.1.0.0.2%3B99411%3A142.0.0.1.2%3B99415%3A126.0.0.1.2; ki_t=1355727898352%3B1372970308875%3B1372970308875%3B60%3B685'}))
  end

  it "parses root uri correctly" do
    content = <<-eos
      GET / HTTP/1.1
Host: localhost:2000
    eos

    stream = StringIO.new(content)

    request = HttpRequest.build(stream)
    expect(request.uri).to(eq(URI('/')))
  end

  it "parses uri path correctly" do
    content = <<-eos
      GET /a/b/c HTTP/1.1
Host: localhost:2000
Connection: keep-alive
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8
    eos

    stream = StringIO.new(content)

    request = HttpRequest.build(stream)
    expect(request.uri).to(eq(URI('/a/b/c')))
  end

  it "parses uri query string correctly" do
    content = <<-eos
      GET /fruits?apples=red&bananas=yellow HTTP/1.1
Host: localhost:2000
Connection: keep-alive
    eos

    stream = StringIO.new(content)

    request = HttpRequest.build(stream)
    expect(request.uri).to(eq(URI('/fruits?apples=red&bananas=yellow')))
  end

  it "recognizes http get methods" do
    content = <<-eos
      GET / HTTP/1.1
Host: localhost:2000
Connection: keep-alive
    eos

    stream = StringIO.new(content)

    request = HttpRequest.build(stream)
    expect(request.get?).to(be(true))
  end

  it "recognizes when http method is not get" do
    content = <<-eos
      POST / HTTP/1.1
Host: localhost:2000
Connection: keep-alive
    eos

    stream = StringIO.new(content)

    request = HttpRequest.build(stream)
    expect(request.get?).to(be(false))
  end

end