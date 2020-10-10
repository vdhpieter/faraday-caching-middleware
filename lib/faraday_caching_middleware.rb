# frozen_string_literal: true

require 'dry-initializer'
require 'Faraday'

class FaradayCachingMiddleware < Faraday::Middleware
  extend Dry::Initializer

  param :app
  # Should be a class implementing the API of ActiveSupport::Cache::Store
  option :store, default: proc { {} }
  option :config, default: proc { {} }

  def call(request_env)
    cached_result = store.fetch(request_env[:url])
    if cached_result
      if cached_result[:expires_on] < Time.now
        Thread.new {
          do_request(request_env)
        }
      end
      cached_result[:response]
    else
      do_request(request_env)
    end
  end

  private

  def do_request(request_env)
    app.call(request_env).on_complete do |response_env|
      store.write request_env[:url], {
        response: response_env,
        expires_on: Time.now + expiry(request_env)
      }, {
        expires_in: grace(request_env)
      }
    end
  end

  def expiry(request_env)
    return config[:expiry] if config&.dig(:expiry)
    5 * 60 # 5 minutes
  end

  def grace(request_env)
    return config[:grace] if config&.dig(:grace)
    30 * 60 # 30 minutes
  end
end
