require "digest/sha1"

require "monkey_party/attendee/field"
require "monkey_party/attendee/has_many_association"
require "monkey_party/attendee/configuration"
require "monkey_party/attendee/mailing"
require "monkey_party/attendee/unsubscriber"

module MonkeyParty
  module Attendee
    def self.included(base)
      base.class_eval do
        named_scope :requires_mailchimp_update,
          :conditions => "sent_to_mailchimp_at IS NULL"

        class_inheritable_hash  :monkey_party_subscriptions

        extend ClassMethods
        before_update :queue_mailchimp_update, :if => :requires_mailchimp_update?

        class << self

          def define_monkey_party_subscription_to(list_name, &block)
            self.monkey_party_subscriptions ||= {}
            configuration = self.monkey_party_subscriptions[list_name] = 
              MonkeyParty::Attendee::Configuration.new(self, &block)
            
            unless MonkeyParty::Attendee.subscribing_classes.include?(self.name)
              MonkeyParty::Attendee.subscribing_classes << self.name
            end
            
            named_scope "#{list_name}_list_subscribers",
              :conditions => "#{configuration.subscription_field.columns[0]} = 1"
            
            named_scope "#{list_name}_list_nonsubscribers",
              :conditions => "#{configuration.subscription_field.columns[0]} = 0
                OR #{configuration.subscription_field.columns[0]} IS NULL"
            

            self.monkey_party_subscriptions[list_name]
          end

          def monkey_party_subscribers_for(list)
            self.send("#{list.name}_list_subscribers".to_sym)
          end

          def monkey_party_nonsubscribers_for(list)
            self.send("#{list.name}_list_nonsubscribers".to_sym)
          end
          
          def monkey_party_subscription_fields
            subscription_fields = []
            self.monkey_party_subscriptions.each do |name, s|
              s.fields.each do |f|
                f.columns.each do |c|
                  subscription_fields << c unless subscription_fields.include?(c)
                end
              end
            end   

            subscription_fields
          end

          def send_to_mailchimp
            lists = []
            monkey_party_subscriptions.each do |name, s|
              list = MonkeyParty::List.find_by_name(name) 
              lists << list unless list.nil?
            end

            lists.each do |list|
              subscriber_scope = monkey_party_subscribers_for(list).requires_mailchimp_update
              nonsubscriber_scope = monkey_party_nonsubscribers_for(list).requires_mailchimp_update

              subscriber_scope.find_in_batches(:batch_size => 10) do |group|
                results = list.create_subscribers(
                  group.collect{|s| s.to_monkey_party_subscriber},
                  {
                    :update_existing => true,
                    :double_optin    => false
                  })
                  
                  process_batch_results(results, group)
              end

              nonsubscriber_scope.find_in_batches(:batch_size => 20) do |group|
                results = list.destroy_subscribers(
                  group.collect{|u| u.to_monkey_party_subscriber }, 
                  :delete_member => true,
                  :send_goodbye  => false)

                process_batch_results(results, group)
              end
            end
          end

          def process_batch_results(results, group)
            index = 0
            self.transaction do
              results.each do |r|
                if r.valid?
                  group[index].sent_to_mailchimp_at = Time.now
                  group[index].mailchimp_error = ""
                else
                  group[index].mailchimp_error = r.error.message
                end
                group[index].save!
                index += 1
              end
            end
          end

        end

      end
    end
    
    def self.subscribing_classes
      @@subscribing_classes ||= []
    end

    def requires_mailchimp_update?
      subscription_fields = self.class.monkey_party_subscription_fields
      self.changes.keys.each do |c|
        return true if subscription_fields.include?(c)
      end

      return false
    end
    
    def queue_mailchimp_update
      self.sent_to_mailchimp_at = nil
    end

    def subscribed_to?(list_name)
      configuration = User.monkey_party_subscriptions[list_name]
      self.send(configuration.subscription_field.columns[0].to_sym)
    end
    
    def to_monkey_party_subscriber(list_name = nil)
      subscriber = MonkeyParty::Subscriber.new(self.email)
      list_name ||= self.class.monkey_party_subscriptions.keys.first

      subscriber.merge_fields = {}
      self.class.monkey_party_subscriptions[list_name].fields.each do |f|
        value = self.send(f.name.to_sym)
        if value.is_a?(Time)
          value = value.strftime("%m/%d/&Y")
        elsif value.nil?
          value = ""
        else
          value = value.to_s
        end
        subscriber.merge_fields[f.merge_field] = value
      end
      
      self.class.monkey_party_subscriptions[list_name].associations.each do |a|
        subscriber.merge_fields.merge!(a.to_merge_field_for(self))
      end
      
      subscriber
    end
  end
end

