module MonkeyParty
  class User < ActiveRecord::Base
    include MonkeyParty::Attendee
    
    define_monkey_party_subscription_to("users") do
      field :login
      field :subscribes_to_site_news, 
        :merge_field => "SITE_NEWS",
        :subscription_column => true

    end
  end
end
