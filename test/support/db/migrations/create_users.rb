ActiveRecord::Base.connection.create_table :users, :force => true do |t|
  t.column :login, :string,  :null => false
  t.column :subscribes_to_site_news, :boolean, :default => true
  t.column :email, :string, :null => false
  t.column :sent_to_mailchimp_at, :datetime
  t.column :mailchimp_error, :string
  t.timestamps
end
 
