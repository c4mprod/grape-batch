require 'spec_helper'
require 'rack/test'
require 'grape/batch'
require 'grape'
require 'api'

RSpec.describe Grape::Batch::Base do
  let(:app) { Twitter::API.new }
  let(:stack) { Grape::Batch::Base.new(app) }
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
      it { expect(response.body).to eq(encode({error: 'Failed as expected'})) }
    end
  end

  describe '/batch' do
    let(:request_body) { nil }
    let(:response) { request.post('/batch', {'CONTENT_TYPE' => 'application/json', input: request_body}) }

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
        let(:request_body) { encode({requests: 'request'}) }
        it { expect(response.body).to eq("'requests' is not well formatted") }
      end

      context 'when request limit is exceeded' do
        let(:request_body) { encode({requests: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]}) }
        it { expect(response.body).to eq('Batch requests limit exceeded') }
      end

      describe 'method attribute in request object' do
        context 'method is missing' do
          let(:request_body) { encode({requests: [{}]}) }
          it { expect(response.body).to eq("'method' is missing in one of request objects") }
        end

        context 'method is not a String' do
          let(:request_body) { encode({requests: [{method: true}]}) }
          it { expect(response.body).to eq("'method' is invalid in one of request objects") }
        end

        context 'method is invalid' do
          let(:request_body) { encode({requests: [{method: 'TRACE'}]}) }
          it { expect(response.body).to eq("'method' is invalid in one of request objects") }
        end
      end

      describe 'path attribute in request object' do
        context 'path is missing' do
          let(:request_body) { encode({requests: [{method: 'GET'}]}) }
          it { expect(response.body).to eq("'path' is missing in one of request objects") }
        end

        context 'path is not a String' do
          let(:request_body) { encode({requests: [{method: 'GET', path: 123}]}) }
          it { expect(response.body).to eq("'path' is invalid in one of request objects") }
        end
      end
    end

    describe 'GET' do
      context 'with no parameters' do
        let(:request_body) { encode({requests: [{method: 'GET', path: '/api/v1/hello'}]}) }
        it { expect(response.status).to eq(200) }
        it { expect(response.body).to eq(encode([{success: 'world'}])) }
      end

      context 'with parameters' do
        let(:request_body) { encode({requests: [{method: 'GET', path: '/api/v1/user/856'}]}) }
        it { expect(response.status).to eq(200) }
        it { expect(response.body).to eq(encode([{success: 'user 856'}])) }
      end

      context 'with a body' do
        let(:request_body) { encode({requests: [{method: 'GET', path: '/api/v1/status', body: {id: 856}}]}) }
        it { expect(response.status).to eq(200) }
        it { expect(response.body).to eq(encode([{success: 'status 856'}])) }
      end

      describe '404 errors' do
        let(:request_body) { encode({requests: [{method: 'GET', path: '/api/v1/unknown'}]}) }
        it { expect(response.status).to eq(200) }
        it { expect(response.body).to eq(encode([{code: 404, message: {error: '/api/v1/unknown not found'}}])) }
      end
    end

    describe 'POST' do
      context 'with no parameters' do
        let(:request_body) { encode({requests: [{method: 'POST', path: '/api/v1/hello'}]}) }
        it { expect(response.status).to eq(200) }
        it { expect(response.body).to eq(encode([{success: 'world'}])) }
      end

      context 'with a body' do
        let(:request_body) { encode({requests: [{method: 'POST', path: '/api/v1/status', body: {id: 856}}]}) }
        it { expect(response.status).to eq(200) }
        it { expect(response.body).to eq(encode([{success: 'status 856'}])) }
      end
    end
  end
end
