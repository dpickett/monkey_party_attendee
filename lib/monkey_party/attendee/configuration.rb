module MonkeyParty
  module Attendee
    class Configuration
      attr_reader :fields, :subscription_field, :finder_options, :associations

      def initialize(klass, &block)
        @fields = []
        @associations = []
        define_configuration(&block) if block_given?
      end

      def define_configuration(&block)
        self.instance_eval &block
        true
      end

      def field(*args)
        options = args.extract_options!
        @fields << MonkeyParty::Attendee::Field.new(args.first, options)
        @subscription_field = @fields.last if options[:subscription_column]
      end

      def has_many(*args)
        options = args.extract_options!
        @associations << MonkeyParty::Attendee::HasManyAssociation.new(args.first, options)
      end
    end
  end
end
