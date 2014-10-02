require 'app/cache'
require 'uri'

describe Cache, "cache" do

  let(:headers) {{'headers' => {'Content-Type' => 'text/html'}}}

  it "fetches subsequent requests from the cache" do
    cache = Cache.new({'cacheDurationSecs' => 10, 'cacheSizeBytes' => 10, 'cacheMaxElementCount' => 2})

    uri = URI('/basic')
    cache.fetch(uri) do
      {'body' => 'load 1'}.merge(headers)
    end
    response = cache.fetch(uri) do
      {'body' => 'load 2'}.merge(headers)
    end
    expect(response['body']).to(eq('load 1'))
  end

  it "does not put items in the cache that are too large" do
    cache = Cache.new({'cacheDurationSecs' => 10, 'cacheSizeBytes' => 10, 'cacheMaxElementCount' => 2})

    uri = URI('/size')
    cache.fetch(uri) do
      {'body' => '12345678901'}.merge(headers)
    end
    response = cache.fetch(uri) do
      {'body' => 'abcdefghijk'}.merge(headers)
    end
    expect(response['body']).to(eq('abcdefghijk'))

  end

  it "does not exceed element count capacity" do
    cache = Cache.new({'cacheDurationSecs' => 10, 'cacheSizeBytes' => 10, 'cacheMaxElementCount' => 2})

    uri = URI('/first')
    cache.fetch(uri) do
      {'body' => 'first 1'}.merge(headers)
    end
    response = cache.fetch(uri) do
      {'body' => 'first 2'}.merge(headers)
    end
    expect(response['body']).to(eq('first 1'))

    uri = URI('/second')
    cache.fetch(uri) do
      {'body' => 'second 1'}.merge(headers)
    end
    response = cache.fetch(uri) do
      {'body' => 'second 2'}.merge(headers)
    end
    expect(response['body']).to(eq('second 1'))

    uri = URI('/third')
    cache.fetch(uri) do
      {'body' => 'third 1'}.merge(headers)
    end
    response = cache.fetch(uri) do
      {'body' => 'third 2'}.merge(headers)
    end
    expect(response['body']).to(eq('third 2'))

  end

  it "expires cache entries" do
    cache = Cache.new({'cacheDurationSecs' => 10, 'cacheSizeBytes' => 100, 'cacheMaxElementCount' => 2})

    uri = URI('/expire')
    response = cache.fetch(uri) do
      {'body' => 'expire me'}.merge(headers)
    end
    response['timestamp'] = (Time.now - 11).to_i

    response = cache.fetch(uri) do
      {'body' => 'new!'}.merge(headers)
    end

    expect(response['body']).to(eq('new!'))

  end

  it "only caches known text content-types" do
    cacheable_content_types = ['text/a', 'text/b', 'json', 'plain', 'random', 'text/html']

    cache = Cache.new({'cacheDurationSecs' => 100, 'cacheSizeBytes' => 100, 'cacheMaxElementCount' => 100,
                       'cacheableContentTypes' => cacheable_content_types})

    ['img/png', 'img/gif', 'application/pdf'].each do |content_type|

      uri = URI('/uncacheable-content-type')
      cache.fetch(uri) do
        {'body' => 'no cache 1', 'headers' => {'Content-Type' => content_type}}
      end

      response = cache.fetch(uri) do
        {'body' => 'no cache 2', 'headers' => {'Content-Type' => content_type}}
      end

      expect(response['body']).to(eq('no cache 2'))
    end

    content_types_with_encoding = ['text/html; charset=utf-8']
    cacheable_content_types = cacheable_content_types + content_types_with_encoding
    cacheable_content_types.each_with_index do |content_type, index|

      uri = URI("/cacheable-content-type-#{index}")
      cache.fetch(uri) do
        {'body' => 'no cache 1', 'headers' => {'Content-Type' => content_type}}
      end

      response = cache.fetch(uri) do
        {'body' => 'no cache 2', 'headers' => {'Content-Type' => content_type}}
      end

      expect(response['body']).to(eq('no cache 1'))
    end

  end

  it "does not cache on empty content-type" do
    cache = Cache.new({'cacheDurationSecs' => 100, 'cacheSizeBytes' => 100, 'cacheMaxElementCount' => 2})

    uri = URI('/no-content-type')
    cache.fetch(uri) do
      {'body' => 'no cache 1', 'headers' => {}}
    end

    response = cache.fetch(uri) do
      {'body' => 'no cache 2'}
    end

    expect(response['body']).to(eq('no cache 2'))
  end

end