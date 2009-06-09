module MonkeyParty
  module Attendee
    class Field
      attr_reader :name, :columns, :merge_field

      def initialize(*args)
        @name = args.first

        options = args.extract_options!

        @merge_field = options[:merge_field] || @name
        @columns = []
        @columns << @name.to_s
      end
    end
  end
end
