require 'socket'
require 'http_request'

class TransparentProxy

  def serve(io)

    STDOUT.puts "=== START ==="

    http_request = HttpRequest.build(io)
    headers = http_request.headers
    uri = http_request.uri

    response = "Hello World!\nTime is #{Time.now}\n\n#{headers.inspect}"

    # We need to include the Content-Type and Content-Length headers
    # to let the client know the size and type of data
    # contained in the response. Note that HTTP is whitespace
    # sensitive, and expects each header line to end with CRLF (i.e. "\r\n")
    #client.print "HTTP/1.1 200 OK\r\n" +
    #                 "Content-Type: text/plain\r\n" +
    #                 "Content-Length: #{response.bytesize}\r\n" +
    #                 "Connection: close\r\n"

    ['HTTP/1.1 200 OK', 'Content-Type: text/plain', "Content-Length: #{response.bytesize}", "Connection: close\r\n"].each do |token|
      io.puts token
    end

    io.puts
    io.puts response

    io.close

    STDOUT.puts "=== END ==="
  end


end

server = TCPServer.new 2000
proxy = TransparentProxy.new

loop do
  Thread.start(server.accept) do |io|
    proxy.serve(io)
  end
end

