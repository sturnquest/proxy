require 'uri'

class HttpRequest

  def initialize(method, uri, headers)
    @method = method
    @uri = uri
    @headers = headers
  end

  def self.build(stream)
    first_line = stream.gets
    method, uri = first_line.split(' ')
    headers = {}

    while ((line = stream.gets))
      break if line.strip.empty?

      tokens = line.strip.split(':')

      name = tokens.shift
      headers[name.strip] = tokens.join(':').strip if name
    end

    HttpRequest.new(method, URI(uri), headers)
  end

  def get?
    @method.strip.upcase == 'GET'
  end

  def headers
    @headers
  end

  def uri
    @uri
  end

end