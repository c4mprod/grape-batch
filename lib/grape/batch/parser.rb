module Grape
  module Batch
    class Validator
      class << self
        def parse(env, limit)
          batch_body = decode_body(env['rack.input'])

          requests = batch_body['requests']
          validate_requests(requests, limit)

          requests.each do |request|
            validate_request(request)
          end

          requests
        end

        private

        def decode_body(body)
          raise RequestBodyError.new('Request body is blank') unless body.length > 0

          begin
            batch_body = MultiJson.decode(body)
          rescue MultiJson::ParseError
            raise RequestBodyError.new('Request body is not valid JSON')
          end

          raise RequestBodyError.new('Request body is nil') unless batch_body
          raise RequestBodyError.new('Request body is not well formatted') unless batch_body.is_a?(Hash)

          batch_body
        end

        def validate_requests(batch_requests, limit)
          raise RequestBodyError.new("'requests' object is missing in request body") unless batch_requests
          raise RequestBodyError.new("'requests' is not well formatted") unless batch_requests.is_a?(Array)
          raise TooManyRequestsError.new('Batch requests limit exceeded') if batch_requests.count > limit
        end

        def validate_request(request)
          raise RequestBodyError.new("'method' is missing in one of request objects") unless request['method']
          raise RequestBodyError.new("'method' is invalid in one of request objects") unless request['method'].is_a?(String)

          unless %w(GET POST PUT DELETE).include?(request['method'])
            raise RequestBodyError.new("'method' is invalid in one of request objects")
          end

          raise RequestBodyError.new("'path' is missing in one of request objects") unless request['path']
          raise RequestBodyError.new("'path' is invalid in one of request objects") unless request['path'].is_a?(String)
        end
      end
    end
  end
end
