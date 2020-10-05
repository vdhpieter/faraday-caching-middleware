require 'faraday'
require 'active_support'

require_relative '../lib/faraday-caching-middleware.rb'

client = Faraday.new("http://worldtimeapi.org") do |builder|
  builder.use FaradayCachingMiddleware, store: ActiveSupport::Cache::MemoryStore.new, config: {
    expiry: 15,
    grace: 30
  }
  builder.use Faraday::Request::UrlEncoded
  builder.use Faraday::Adapter::NetHttp
end

p "=== First request ==="
p client.get("/api/ip")

p "=== sleeping for 15 seconds ==="
sleep 15

p "=== Second request after 15s (will return cache and refetch in the background) ==="
p client.get("/api/ip")

p "=== sleeping for 5 seconds ==="
sleep 5

p "=== Third request after 5s (will return refetched response) ==="
p client.get("/api/ip")

p "=== sleeping for 30 seconds ==="
sleep 30

p "=== Fourth request after 30s (will not return cache and refetch) ==="
p client.get("/api/ip")

p "=== Fifth request, with different url to test overriden config ==="
p client.get("/api/ip", {test: 123}) do |req|
  # Does not work for now
  req.options.context = {
    expiry: 0,
    grace: 0
  }
end

p "=== Sixth request, with different url that should not be cached because of overriden config ==="
p client.get("/api/ip", {test: 123})
