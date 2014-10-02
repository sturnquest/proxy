class Cache

  def initialize(attributes)
    @cacheDurationSecs = attributes['cacheDurationSecs']
    @cacheSizeBytes = attributes['cacheSizeBytes']
    @cacheMaxElementCount = attributes['cacheMaxElementCount']

    @cache = {}
  end

  #{
  #    uri.to_s => {
  #        'headers' => {},
  #        'body' => '',
  #        'timestamp' => 1
  #    }
  #}
  def fetch(uri)

    now = Time.now
    @cache.keys.each do |key|
      timestamp = @cache[key]['timestamp']
      if (now - Time.at(timestamp) > @cacheDurationSecs)
        @cache.delete(key)
      end
    end

    cached = @cache[uri.to_s]

    if (cached)
      cached
    else
      raw = yield(uri)

      if ((raw['body'].bytesize <= @cacheSizeBytes) && (@cache.keys.size < @cacheMaxElementCount))
        raw['timestamp'] = Time.now.to_i
        @cache[uri.to_s] = raw
      end

      raw
    end

  end



end