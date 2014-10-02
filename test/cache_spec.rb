require 'app/cache'
require 'uri'

describe Cache, "cache" do

  it "fetches subsequent requests from the cache" do
    cache = Cache.new({'cacheDurationSecs' => 10, 'cacheSizeBytes' => 10, 'cacheMaxElementCount' => 2})

    uri = URI('/basic')
    cache.fetch(uri) do |uri|
      {'body' => 'load 1'}
    end
    response = cache.fetch(uri) do |uri|
      {'body' => 'load 2'}
    end
    expect(response['body']).to(eq('load 1'))
  end

  it "does not put items in the cache that are too large" do
    cache = Cache.new({'cacheDurationSecs' => 10, 'cacheSizeBytes' => 10, 'cacheMaxElementCount' => 2})

    uri = URI('/size')
    cache.fetch(uri) do |uri|
      {'body' => '12345678901'}
    end
    response = cache.fetch(uri) do |uri|
      {'body' => 'abcdefghijk'}
    end
    expect(response['body']).to(eq('abcdefghijk'))

  end

  it "does not exceed element count capacity" do
    cache = Cache.new({'cacheDurationSecs' => 10, 'cacheSizeBytes' => 10, 'cacheMaxElementCount' => 2})

    uri = URI('/first')
    cache.fetch(uri) do |uri|
      {'body' => 'first 1'}
    end
    response = cache.fetch(uri) do |uri|
      {'body' => 'first 2'}
    end
    expect(response['body']).to(eq('first 1'))

    uri = URI('/second')
    cache.fetch(uri) do |uri|
      {'body' => 'second 1'}
    end
    response = cache.fetch(uri) do |uri|
      {'body' => 'second 2'}
    end
    expect(response['body']).to(eq('second 1'))

    uri = URI('/third')
    cache.fetch(uri) do |uri|
      {'body' => 'third 1'}
    end
    response = cache.fetch(uri) do |uri|
      {'body' => 'third 2'}
    end
    expect(response['body']).to(eq('third 2'))

  end

  it "expires cache entries" do
    cache = Cache.new({'cacheDurationSecs' => 10, 'cacheSizeBytes' => 100, 'cacheMaxElementCount' => 2})

    uri = URI('/expire')
    response = cache.fetch(uri) do |uri|
      {'body' => 'expire me'}
    end
    response['timestamp'] = (Time.now - 11).to_i

    response = cache.fetch(uri) do |uri|
      {'body' => 'new!'}
    end

    expect(response['body']).to(eq('new!'))

  end

end