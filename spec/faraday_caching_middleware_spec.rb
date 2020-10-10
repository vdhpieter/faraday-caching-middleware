require "./lib/faraday_caching_middleware"

RSpec.describe FaradayCachingMiddleware do
  let(:faraday_app) { double('faraday_app', call: response_app) }
  let(:response_app) { double('response') }
  let(:request_env) { {url: 'test.com/123' } }
  let(:response_env) { {body: 'test'} }
  let(:store) { double('store', write: true, fetch: stored_response) }
  let(:stored_response) { nil }
  let(:config) { {expiry: 2, grace: 4} }

  let(:subject) { described_class.new(faraday_app, store: store, config: config) }

  before do
    allow(response_app).to receive(:on_complete).and_yield(response_env)
  end

  it "stores a request in the cache with the right expires_in time" do
    expect(store).to receive(:write).with(request_env[:url], anything, { expires_in: config[:grace]})

    subject.call(request_env)
  end

  it "stores a request in the cache with the right format" do
    expect(Time).to receive(:now).and_return(0)

    expect(store).to receive(:write).with(request_env[:url], {response: response_env, expires_on: config[:expiry]}, anything)

    subject.call(request_env)
  end

  context "with no config" do
    let(:config) { nil }

    it 'falls back to defaults' do
      expect(Time).to receive(:now).and_return(0)

      expect(store).to receive(:write).with(request_env[:url], {response: anything, expires_on: 5*60}, expires_in: 30*60 )

      subject.call(request_env)
    end
  end

  context "when a response is cached" do
    let(:stored_response) { {response: 'stored_response', expires_on: Time.now + 100} }

    it "returns that one" do
      expect((subject).call(request_env)).to eq(stored_response[:response])
    end
  end

  context "when an expired response is cached" do
    let(:stored_response) { {response: 'stored_response', expires_on: Time.now - 100} }

    it "returns that one and fetches a new one" do
      expect(Thread).to receive(:new)

      expect((subject).call(request_env)).to eq(stored_response[:response])
    end
  end
end
