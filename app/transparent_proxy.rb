require 'rubygems'
require 'socket'
require 'http_request'
require 'http_response'
require 'cache'
require 'stringio'
require 'json'

class TransparentProxy

  def initialize(cache, attributes)
    @@cache = cache
    @proxied_base_url = attributes['proxiedBaseUrl']
    @ignore_extensions = attributes['ignoreExtensions']
  end

  def serve(io)
    http_request = HttpRequest.build(io)
    headers = http_request.headers
    uri = http_request.uri
    proxied_uri = URI("#{@proxied_base_url}#{uri.to_s}")

    # ignore certain requests. e.g. chrome and firefox automatically look for a favicon.ico
    if (@ignore_extensions.any? {|extension| proxied_uri.path.end_with?(".#{extension}")})
      STDOUT.puts "ignoring: #{proxied_uri}"
      io.close
      return
    end

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
cache = Cache.new(JSON.load(IO.read('cache.json')))
proxy = TransparentProxy.new(cache, JSON.load(IO.read('proxy.json')))

loop do
  Thread.start(proxy_server.accept) do |io|
    proxy.serve(io)
  end
end

