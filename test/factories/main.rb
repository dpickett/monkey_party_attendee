Factory.define :user, :class => MonkeyParty::User do |u|
  u.login "jsmith"
  u.email "jsmith@example.com"
  u.subscribes_to_site_news true
end
