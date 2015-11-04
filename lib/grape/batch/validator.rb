module Grape
  module Batch
    # Parse and validate request params and ensure it is a valid batch request
    class Validator
      class << self
        def parse(env, limit)
          batch_body = decode_body(env['rack.input'].read)

          requests = batch_body['requests']
          validate_requests(requests, limit)
          requests.each { |request| validate_request(request) }

          requests
        end

        private

        def decode_body(body)
          fail RequestBodyError, 'Request body is blank' unless body.length > 0

          begin
            batch_body = MultiJson.decode(body)
          rescue MultiJson::ParseError
            raise RequestBodyError, 'Request body is not valid JSON'
          end

          fail RequestBodyError, 'Request body is nil' unless batch_body
          fail RequestBodyError, 'Request body is not well formatted' unless batch_body.is_a?(Hash)

          batch_body
        end

        def validate_requests(batch_requests, limit)
          fail RequestBodyError, "'requests' object is missing in request body" unless batch_requests
          fail RequestBodyError, "'requests' is not well formatted" unless batch_requests.is_a?(Array)
          fail TooManyRequestsError, 'Batch requests limit exceeded' if batch_requests.count > limit
        end

        def validate_request(request)
          fail RequestBodyError, "'method' is missing in one of request objects" unless request['method']
          fail RequestBodyError, "'method' is invalid in one of request objects" unless request['method'].is_a?(String)

          unless %w(GET DELETE PATCH POST PUT).include?(request['method'])
            fail RequestBodyError, "'method' is invalid in one of request objects"
          end

          fail RequestBodyError, "'path' is missing in one of request objects" unless request['path']
          fail RequestBodyError, "'path' is invalid in one of request objects" unless request['path'].is_a?(String)
        end
      end
    end
  end
end
