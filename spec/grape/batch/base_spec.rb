require 'spec_helper'
require 'rack/test'
require 'grape'
require 'grape/base'
require 'api'

RSpec.describe Grape::Batch::Base do
  before(:all) do
    Grape::Batch.configuration.logger = Logger.new('/dev/null')
  end

  before :context do
    @app = Twitter::API.new
  end

  let(:stack) { described_class.new(@app) }
  let(:request) { Rack::MockRequest.new(stack) }

  def encode(message)
    MultiJson.encode(message)
  end

  def decode(message)
    MultiJson.decode(message)
  end

  describe '/api' do
    describe 'GET /hello' do
      let(:response) { request.get('/api/v1/hello') }

      it { expect(response.status).to eq(200) }
      it { expect(response.body).to eq(encode('world')) }
    end

    describe 'GET /failure' do
      let(:response) { request.get('/api/v1/failure') }
      it { expect(response.status).to eq(503) }
      it { expect(response.body).to eq(encode(error: 'Failed as expected')) }
    end
  end

  describe '/batch' do
    let(:request_body) { nil }
    let(:options) { { 'CONTENT_TYPE' => 'application/json', input: request_body } }
    let(:response) { request.post('/batch', options) }

    context 'with invalid body' do
      it { expect(response.status).to eq(400) }

      context 'when body == nil' do
        it { expect(response.body).to eq('Request body is blank') }
      end

      context 'when body is empty' do
        let(:request_body) { '' }
        it { expect(response.body).to eq('Request body is blank') }
      end

      context 'when body is not valid JSON' do
        let(:request_body) { 'ads[}' }
        it { expect(response.body).to eq('Request body is not valid JSON') }
      end

      context 'when body == null' do
        let(:request_body) { 'null' }
        it { expect(response.body).to eq('Request body is nil') }
      end

      context 'when body is not a hash' do
        let(:request_body) { '[1, 2, 3]' }
        it { expect(response.body).to eq('Request body is not well formatted') }
      end

      context "when body['requests'] == nil" do
        let(:request_body) { '{}' }
        it { expect(response.body).to eq("'requests' object is missing in request body") }
      end

      context "when body['requests'] is not an array" do
        let(:request_body) { encode(requests: 'request') }
        it { expect(response.body).to eq("'requests' is not well formatted") }
      end

      context 'when request limit is exceeded' do
        let(:request_body) { encode(requests: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]) }
        it { expect(response.body).to eq('Batch requests limit exceeded') }
      end

      describe 'method attribute in request object' do
        context 'method is missing' do
          let(:request_body) { encode(requests: [{}]) }
          it { expect(response.body).to eq("'method' is missing in one of request objects") }
        end

        context 'method is not a String' do
          let(:request_body) { encode(requests: [{ method: true }]) }
          it { expect(response.body).to eq("'method' is invalid in one of request objects") }
        end

        context 'method is invalid' do
          let(:request_body) { encode(requests: [{ method: 'TRACE' }]) }
          it { expect(response.body).to eq("'method' is invalid in one of request objects") }
        end
      end

      describe 'path attribute in request object' do
        context 'path is missing' do
          let(:request_body) { encode(requests: [{ method: 'GET' }]) }
          it { expect(response.body).to eq("'path' is missing in one of request objects") }
        end

        context 'path is not a String' do
          let(:request_body) { encode(requests: [{ method: 'GET', path: 123 }]) }
          it { expect(response.body).to eq("'path' is invalid in one of request objects") }
        end
      end
    end

    describe 'GET' do
      context 'with no parameters' do
        let(:request_body) { encode(requests: [{ method: 'GET', path: '/api/v1/hello' }]) }
        it { expect(response.status).to eq(200) }
        it { expect(response.body).to eq(encode([{ success: 'world' }])) }
      end

      context 'with parameters' do
        let(:request_body) { encode(requests: [{ method: 'GET', path: '/api/v1/user/856' }]) }
        it { expect(response.status).to eq(200) }
        it { expect(response.body).to eq(encode([{ success: 'user 856' }])) }
      end

      context 'with a body' do
        let(:path) { '/api/v1/status' }
        let(:request_body) { encode(requests: [{ method: 'GET', path: path, body: { id: 856 } }]) }
        it { expect(response.status).to eq(200) }
        it { expect(response.body).to eq(encode([{ success: 'status 856' }])) }
      end

      context 'with a body and nested hash' do
        let(:path) { '/api/v1/complex' }
        let(:complex) { { a: { b: { c: 1 } } } }
        let(:request_body) { encode(requests: [{ method: 'GET', path: path, body: complex }]) }
        it { expect(response.status).to eq(200) }
        it { expect(response.body).to eq(encode([{ success: 'hash 1' }])) }
      end

      describe '404 errors' do
        let(:request_body) { encode(requests: [{ method: 'GET', path: '/api/v1/unknown' }]) }
        let(:expected_error) { { code: 404, error: '/api/v1/unknown not found' } }
        it { expect(response.status).to eq(200) }
        it { expect(response.body).to eq(encode([expected_error])) }
      end
    end

    describe 'POST' do
      context 'with no parameters' do
        let(:request_body) { encode(requests: [{ method: 'POST', path: '/api/v1/hello' }]) }
        it { expect(response.status).to eq(200) }
        it { expect(response.body).to eq(encode([{ success: 'world' }])) }
      end

      context 'with a body' do
        let(:path) { '/api/v1/status' }
        let(:body) { { id: 856 } }
        let(:request_body) { encode(requests: [{ method: 'POST', path: path, body: body }]) }
        it { expect(response.status).to eq(200) }
        it { expect(response.body).to eq(encode([{ success: 'status 856' }])) }
      end
    end

    describe 'POST' do
      context 'with multiple requests' do
        let(:request_1) { { method: 'POST', path: '/api/v1/hello' } }
        let(:request_2) { { method: 'GET', path: '/api/v1/user/856' } }
        let(:request_body) { encode(requests: [request_1, request_2]) }
        it { expect(response.status).to eq(200) }
        it { expect(decode(response.body).size).to eq(2) }
      end
    end

    describe 'single session' do
      describe 'without token' do
        let(:request_1) { { method: 'POST', path: '/api/v1/login' } }
        let(:request_body) { encode(requests: [request_1]) }
        it { expect(response.status).to eq(200) }
        it { expect(response.body).to eq(encode([{ success: 'token invalid' }])) }
        it { expect(response.headers).to_not include('HTTP_X_API_TOKEN') }
      end

      describe 'with a token' do
        let(:request_1) { { method: 'GET', path: '/api/v1/login' } }
        let(:request_2) { { method: 'POST', path: '/api/v1/login' } }
        let(:request_body) { encode(requests: [request_1, request_2]) }
        let(:expected_response) { [{ success: 'login successful' }, { success: 'token valid' }] }
        it { expect(response.status).to eq(200) }
        it { expect(response.body).to eq(encode(expected_response)) }
        it { expect(response.headers).to_not include('HTTP_X_API_TOKEN') }
      end

      describe 'without session' do
        let(:request_1) { { method: 'POST', path: '/api/v1/session' } }
        let(:request_body) { encode(requests: [request_1]) }
        it { expect(response.status).to eq(200) }
        it { expect(response.body).to eq(encode([{ success: 'session invalid' }])) }
        it { expect(response.headers).to_not include('api.session') }
      end

      describe 'with a session' do
        let(:request_1) { { method: 'GET', path: '/api/v1/session' } }
        let(:request_2) { { method: 'POST', path: '/api/v1/session' } }
        let(:request_body) { encode(requests: [request_1, request_2]) }
        let(:expected_response) { [{ success: 'session reloaded' }, { success: 'session valid' }] }
        it { expect(response.status).to eq(200) }
        it { expect(response.body).to eq(encode(expected_response)) }
        it { expect(response.headers).to_not include('api.session') }
      end
    end
  end

  describe '#configure' do
    it { expect(Grape::Batch.configuration).to_not be_nil }

    describe 'default_value' do
      it { expect(Grape::Batch.configuration.path).to eq('/batch') }
      it { expect(Grape::Batch.configuration.formatter).to eq(Grape::Batch::Response) }
      it { expect(Grape::Batch.configuration.limit).to eq(10) }
    end

    describe '.configure' do
      before do
        allow(Grape::Batch).to receive(:configuration) do
          config = Grape::Batch::Configuration.new
          config.path = '/custom_path'
          config.limit = 15
          config.session_proc = proc { 3 + 2 }
          config
        end
      end

      describe 'default_value' do
        it { expect(Grape::Batch.configuration.path).to eq('/custom_path') }
        it { expect(Grape::Batch.configuration.limit).to eq(15) }
        it { expect(Grape::Batch.configuration.session_proc.call).to eq(5) }
      end
    end
  end
end
