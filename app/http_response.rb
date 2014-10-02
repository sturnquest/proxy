require 'uri'

class HttpResponse

  def initialize(status_line, headers, body)
    @status_line = status_line
    @headers = headers
    @body = body
  end

  def self.build(stream)
    status_line = stream.gets
    headers = {}

    while (line = stream.gets)
      break if line.strip.empty?

      tokens = line.strip.split(':')

      name = tokens.shift
      headers[name.strip] = tokens.join(':').strip if name
    end

    body = []
    while (line = stream.gets)
      break if line.empty?

      body << line
    end

    HttpResponse.new(status_line.strip, headers, body.join)
  end

  def body
    @body
  end

  def headers
    @headers
  end

  def status_line
    @status_line
  end

end