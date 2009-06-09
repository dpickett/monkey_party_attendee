module MonkeyParty
  module Attendee
    class Mailing
      attr_reader :name, :subscription_toggler_field, :unsubscribe_key_field

      def initialize(name)
        @name = name.to_s
        @subscription_toggler_field = "subscribes_to_#{@name}"
        @unsubscribe_key_field = "#{@name}_key"
      end
    end
  end
end
