Get Started
===========

<p>A simple transparent caching proxy for GET requests.</p>

> 1. git clone git://github.com/sturnquest/proxy.git
> 2. cd proxy
> 3. bundle
> 4. rspec test
> 5. cd app
> 6. ruby transparent_proxy.rb
> 7. in a browser open http://localhost:2000/proxied/one

<p>
By default the proxy is configured to hit a known end point. You can change the end point in the proxy.json file.
Make sure the configured end is not compressing the response (e.g. a header with Content-Encoding:gzip).
</p>

<p>
By default the cache will only cache responses with a known text content-type.
</p>

<p>
For live testing beyond the specs open up 3 separate browser windows with the following urls:
</p>

> http://localhost:2000/proxied/one
> http://localhost:2000/proxied/two
> http://localhost:2000/proxied/three

<p>
As you refresh each of the above browser windows two will remain cached and the 3rd will not be cached.
You can change the number of allowed cached items in cache.json
</p>

