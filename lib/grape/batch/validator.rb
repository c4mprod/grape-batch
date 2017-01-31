module Grape
  module Batch
    # Parse and validate request params and ensure it is a valid batch request
    class Validator
      ALLOWED_METHODS = %w(GET DELETE PATCH POST PUT)

      class << self
        def parse(env, limit, logger = nil)
          input = env['rack.input'].read
          if logger
            logger.info('DEBUG BODY')
            logger.info(input)
          end
          batch_body = decode_body(input)

          requests = batch_body['requests']
          validate_batch(requests, limit)
          requests.each { |request| validate_request(request) }

          requests
        end

        private

        def decode_body(body)
          fail RequestBodyError::Blank unless body.length > 0

          begin
            batch_body = MultiJson.decode(body)
          rescue MultiJson::ParseError
            raise RequestBodyError::JsonFormat
          end

          fail RequestBodyError::Nil unless batch_body
          fail RequestBodyError::Format unless batch_body.is_a?(Hash)

          batch_body
        end

        def validate_batch(batch_requests, limit)
          fail RequestBodyError::MissingRequests unless batch_requests
          fail RequestBodyError::RequestFormat unless batch_requests.is_a?(Array)
          fail TooManyRequestsError if batch_requests.count > limit
        end

        def validate_request(request)
          fail RequestBodyError::MissingMethod unless request['method']
          fail RequestBodyError::MethodFormat unless request['method'].is_a?(String)
          fail RequestBodyError::InvalidMethod unless ALLOWED_METHODS.include?(request['method'])
          fail RequestBodyError::MissingPath unless request['path']
          fail RequestBodyError::InvalidPath unless request['path'].is_a?(String)
        end
      end
    end
  end
end
