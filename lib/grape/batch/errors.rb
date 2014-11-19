module Grape
  module Batch
    class RequestBodyError < ArgumentError; end
    class TooManyRequestsError < StandardError; end
  end
end
