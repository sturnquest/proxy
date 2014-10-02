require 'socket'
require 'http_request'
require 'http_response'
require 'cache'
require 'stringio'

class TransparentProxy

  def initialize(cache)
    @@cache = cache
  end

  def serve(io)
    http_request = HttpRequest.build(io)
    headers = http_request.headers
    uri = http_request.uri
    proxied_uri = URI("http://test.bahamago.com#{uri.to_s}")

    STDOUT.puts "proxied server address: #{proxied_uri}"

    response = @@cache.fetch(uri) do
      curl_headers = headers.map {|key, value| "-H \"#{key}: #{value}\""}.join(' ')
      curl_response = `curl -i #{curl_headers} '#{proxied_uri}'`

      stream = StringIO.new(curl_response)
      http_response = HttpResponse.build(stream)
      headers = http_response.headers
      body = http_response.body

      #replace chunked transfer encoding with the content length since our proxy does not chunk
      headers.delete('Transfer-Encoding')
      headers['Content-Length'] = body.bytesize

      {'status' => http_response.status_line, 'headers' => headers, 'body' => body}
    end

    io.puts response['status']
    headers = response['headers']

    headers.map do |key, value|
      io.puts "#{key}: #{value}"
    end

    io.puts
    io.puts response['body']
    io.close
  end


end

proxy_server = TCPServer.new 2000
cache = Cache.new({'cacheDurationSecs' => 60, 'cacheSizeBytes' => (1024 * 10), 'cacheMaxElementCount' => 2})
proxy = TransparentProxy.new(cache)

loop do
  Thread.start(proxy_server.accept) do |io|
    proxy.serve(io)
  end
end

