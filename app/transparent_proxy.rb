require 'rubygems'
require 'socket'
require File.join(File.dirname(__FILE__), 'http_request')
require File.join(File.dirname(__FILE__), 'http_response')
require File.join(File.dirname(__FILE__), 'cache')
require 'stringio'
require 'json'

class TransparentProxy

  def initialize(cache, attributes)
    @@cache = cache
    @proxied_base_url = attributes['proxiedBaseUrl']
  end

  def serve(io)
    http_request = HttpRequest.build(io)
    headers = http_request.headers
    uri = http_request.uri
    proxied_uri = URI("#{@proxied_base_url}#{uri.to_s}")

    unless (http_request.get?)
      STDOUT.puts "ignoring: #{proxied_uri}"
      io.puts "HTTP/1.1 405 Method Not Allowed"
      io.puts "Allow: GET"
      io.close
      return
    end

    STDOUT.puts "proxied address: #{proxied_uri}"

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

      unless (http_response.ok?)
        STDOUT.puts "non 200 response. status line: #{http_response.status_line}. proxied address: #{proxied_uri}"
      end

      {'status' => http_response.status_line, 'headers' => headers, 'body' => body}
    end

    io.puts response['status']
    headers = response['headers']

    headers.map do |key, value|
      io.puts "#{key}: #{value}"
    end

    #http spec requires an empty line between header and response body
    io.puts
    io.puts response['body']
    io.close
  end


end

proxy_server = TCPServer.new 2000
cache = Cache.new(JSON.load(IO.read(File.join(File.dirname(__FILE__), 'cache.json'))))
proxy = TransparentProxy.new(cache, JSON.load(IO.read(File.join(File.dirname(__FILE__), 'proxy.json'))))

loop do
  Thread.start(proxy_server.accept) do |io|
    proxy.serve(io)
  end
end

