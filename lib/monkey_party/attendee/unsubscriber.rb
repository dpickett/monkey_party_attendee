module MonkeyParty
  module Attendee
    module Unsubscriber
      
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          extend ClassMethods
          class_inheritable_hash :mailings
          attr_reader :last_unsubscribed_mailing
        end
      end
    end

    module ClassMethods
      def unsubscribes_from(mailing_name)
        self.mailings ||= {}
        self.mailings[mailing_name] = MonkeyParty::Attendee::Mailing.new(mailing_name)

        before_create :create_unsubscription_keys
      end
    end

    module InstanceMethods
      def unsubscribe(key)
        self.class.mailings.each do |name, mailing|
          if self[mailing.unsubscribe_key_field] == key
            self[mailing.subscription_toggler_field] = false
            create_unsubscription_key_for(mailing)
            @last_unsubscribed_mailing = mailing

            return self.save
          end
        end
        return false
      end

      def create_unsubscription_keys
        self.class.mailings.each do |name, mailing|
          create_unsubscription_key_for(mailing)
        end
      end

      def create_unsubscription_key_for(mailing)
        self["#{mailing.unsubscribe_key_field}"] =  Digest::SHA1.hexdigest(
          "#{Time.now}--#{(1..10).map{ rand.to_s}}")
      end
    end
  end
end
