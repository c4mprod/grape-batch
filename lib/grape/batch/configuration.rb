module Grape
  module Batch
    class Configuration
      attr_accessor :path, :limit, :formatter

      def initialize
        @path  = '/batch'
        @limit = 10
        @formatter = Grape::Batch::Response
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