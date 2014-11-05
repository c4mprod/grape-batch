module Grape
  module Batch
    class RequestBodyError < ArgumentError; end
    class TooManyRequestsError < StandardError; end

    class Validator
      def self.parse(env, limit)
        rack_input = env['rack.input'].read
        raise RequestBodyError.new('Request body is blank') unless rack_input.length > 0

        begin
          batch_body = MultiJson.decode(rack_input)
        rescue MultiJson::ParseError
          raise RequestBodyError.new('Request body is not valid JSON')
        end

        raise RequestBodyError.new('Request body is nil') unless batch_body
        raise RequestBodyError.new('Request body is not well formatted') unless batch_body.is_a?(Hash)

        batch_requests = batch_body['requests']
        raise RequestBodyError.new("'requests' object is missing in request body") unless batch_requests
        raise RequestBodyError.new("'requests' is not well formatted") unless batch_requests.is_a?(Array)
        raise TooManyRequestsError.new('Batch requests limit exceeded') if batch_requests.count > limit

        batch_requests.each do |request|
          raise RequestBodyError.new("'method' is missing in one of request objects") unless request['method']
          raise RequestBodyError.new("'method' is invalid in one of request objects") unless request['method'].is_a?(String)
          unless ['GET', 'POST', 'PUT', 'DELETE'].include?(request['method'])
            raise RequestBodyError.new("'method' is invalid in one of request objects")
          end

          raise RequestBodyError.new("'path' is missing in one of request objects") unless request['path']
          raise RequestBodyError.new("'path' is invalid in one of request objects") unless request['path'].is_a?(String)
        end

        batch_requests
      end
    end
  end
end
