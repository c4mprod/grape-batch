module Grape
  module Batch
    class RequestBodyError < ArgumentError
      # Request body is blank
      class Blank < RequestBodyError
        def initialize
          super('Request body is blank')
        end
      end

      # Request body is not properly formatted JSON
      class JsonFormat < RequestBodyError
        def initialize
          super('Request body is not valid JSON')
        end
      end

      # Batch body is nil
      class Nil < RequestBodyError
        def initialize
          super('Request body is nil')
        end
      end

      # Batch body isn't properly formatted as a Hash
      class Format < RequestBodyError
        def initialize
          super('Request body is not well formatted')
        end
      end

      # Some requests attributes are missing in the batch body
      class MissingRequests < RequestBodyError
        def initialize
          super("'requests' object is missing in request body")
        end
      end

      # Some requests attributes aren't properly formatted as an Array
      class RequestFormat < RequestBodyError
        def initialize
          super("'requests' is not well formatted")
        end
      end

      # Batch request method is missing
      class MissingMethod < RequestBodyError
        def initialize
          super("'method' is missing in one of request objects")
        end
      end

      # Batch request method isn't properly formatted as a String
      class MethodFormat < RequestBodyError
        def initialize
          super("'method' is invalid in one of request objects")
        end
      end

      # Batch request method aren't allowed
      class InvalidMethod < RequestBodyError
        def initialize
          super("'method' is invalid in one of request objects")
        end
      end

      # Batch request path is missing
      class MissingPath < RequestBodyError
        def initialize
          super("'path' is missing in one of request objects")
        end
      end

      # Batch request path isn't properly formatted as a String
      class InvalidPath < RequestBodyError
        def initialize
          super("'path' is invalid in one of request objects")
        end
      end
    end

    # Batch exceeds request limit
    class TooManyRequestsError < StandardError
      def initialize
        super('Batch requests limit exceeded')
      end
    end
  end
end
