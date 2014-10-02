class Cache

  def initialize(attributes)
    @cacheDurationSecs = attributes['cacheDurationSecs']
    @cacheSizeBytes = attributes['cacheSizeBytes']
    @cacheMaxElementCount = attributes['cacheMaxElementCount']
    @cacheableContentTypes = attributes['cacheableContentTypes'] || ['text/html', 'text/css', 'text/xml', 'application/x-javascript', 'application/atom+xml', 'application/rss+xml', 'application/json', 'text/plain']

    @cache = {}
  end

  #raw = {
  #    '/example/url/path' => {
  #        'headers' => {},
  #        'body' => '',
  #        'timestamp' => 1
  #    }
  #}
  def fetch(uri)

    @cache.delete_if {|key, value| expired?(key)}

    results = @cache[uri.to_s]

    if (results)
      STDOUT.puts "cache hit: #{uri.to_s}"
      results
    else
      raw = yield(uri)

      if (cacheable?(raw))
        raw['timestamp'] = Time.now.to_i
        @cache[uri.to_s] = raw
      end

      raw
    end

  end

  protected

  def expired?(key)
    (Time.now - Time.at(@cache[key]['timestamp'])) > @cacheDurationSecs
  end

  def cacheable?(raw)
    !(too_large?(raw) || too_many?) && cacheable_content_type?(raw)
  end

  def too_large?(raw)
    current_total_bytes = @cache.values.reduce(0) {|sum, hash| sum + hash['body'].bytesize}
    (current_total_bytes + raw['body'].bytesize) > @cacheSizeBytes
  end

  def too_many?
    @cache.keys.size >= @cacheMaxElementCount
  end

  def cacheable_content_type?(raw)
    content_type = ''

    if (headers = raw['headers'])
      content_type = headers['Content-Type']
      content_type = content_type.split(';').first if content_type
    end

    @cacheableContentTypes.include?(content_type)
  end

end