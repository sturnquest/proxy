require 'app/http_response'

describe HttpResponse do

  it "parses headers correctly" do
    content = <<-eos
      HTTP/1.1 200 OK
Content-Type: text/html; charset=utf-8
Transfer-Encoding: chunked
Connection: keep-alive
Keep-Alive: timeout=5
Status: 200
ETag: "28852a5413fce74e1efce5f59ffe4826"
Cache-Control: no-cache

    eos

    stream = StringIO.new(content)

    response = HttpResponse.build(stream)
    expect(response.headers).to(eq({'Content-Type' => 'text/html; charset=utf-8', 'Transfer-Encoding' => 'chunked',
                                   'Connection' => 'keep-alive', 'Keep-Alive' => 'timeout=5', 'Status' => '200',
                                   'ETag' => '"28852a5413fce74e1efce5f59ffe4826"', 'Cache-Control' => 'no-cache'}))
  end

  it "parses status line correctly" do
    content = <<-eos
      HTTP/1.1 200 OK
Content-Type: text/html; charset=utf-8
    eos

    stream = StringIO.new(content)

    response = HttpResponse.build(stream)
    expect(response.status_line).to(eq('HTTP/1.1 200 OK'))
    expect(response.ok?).to(be(true))
  end

  it "parses response body correctly" do
    content = <<-eos
      HTTP/1.1 200 OK
Content-Type: text/html; charset=utf-8

<p>Time at page load is: Thu Oct 02 10:17:20 +0000 2014</p>

<p>Requested URI: /proxied/one</p>
    eos

    body = <<-eos
<p>Time at page load is: Thu Oct 02 10:17:20 +0000 2014</p>

<p>Requested URI: /proxied/one</p>
    eos

    stream = StringIO.new(content)

    response = HttpResponse.build(stream)
    expect(response.body).to(eq(body))
  end

  it "parses a non-200 response" do
    content = <<-eos
HTTP/1.1 204 No Content
Server: nginx
Date: Thu, 02 Oct 2014 19:17:39 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Expires: Thu, 02 Oct 2014 19:17:38 GMT
Cache-Control: no-cache

    eos

    stream = StringIO.new(content)

    response = HttpResponse.build(stream)
    expect(response.ok?).to(be(false))
    expect(response.body).to(eq(''))
  end

end