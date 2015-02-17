module Grape
  module Batch
    class Configuration
      attr_accessor :path, :limit, :formatter, :logger

      def initialize
        @path  = '/batch'
        @limit = 10
        @formatter = Grape::Batch::Response
        @logger = nil
      end
    end

    # Set default configuration for Grape::Batch middleware
    class << self
      attr_accessor :configuration
    end

    def self.configuration
      @configuration ||= Configuration.new
    end

    def self.configuration=(config)
      @configuration = config
    end

    def self.configure
      yield configuration
    end
  end
end