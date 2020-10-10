# Faraday Caching Middleware

**:warning: :warning: This is a POC! Do not use this in production! :warning: :warning:**

This is a middleware to cache faraday responses. It can be configured with two options:

- `store`: A cache store following the `ActiveSupport::Cache` API
- `config`: a hash with 2 options:
  - `expiry`: This should be an amount of time in seconds. During this amount of time the cached response will be returned directly. If this amount of time has passed the cached response will be returned but a new request one will be done in the background.
  - `grace`: This should be an amount of time in seconds. If this amount of time has passed a new call will be done immediately and stored in the cache.

example usage (with rails):

```ruby
client = Faraday.new("http://worldtimeapi.org") do |builder|
  builder.use FaradayCachingMiddleware, store: Rails.cache, config: {
    expiry: 2.minutes,
    grace: 5.minutes
  }
  builder.use Faraday::Request::UrlEncoded
  builder.use Faraday::Adapter::NetHttp
end
```

It also can be used without rails but the `store` param expects a caching store that follow the `ActiveSupport::Cache` API

example usage (without rails):

```ruby
client = Faraday.new("http://worldtimeapi.org") do |builder|
  builder.use FaradayCachingMiddleware, store: ActiveSupport::Cache::MemoryStore.new, config: {
    expiry: 15,
    grace: 30
  }
  builder.use Faraday::Request::UrlEncoded
  builder.use Faraday::Adapter::NetHttp
end
```
