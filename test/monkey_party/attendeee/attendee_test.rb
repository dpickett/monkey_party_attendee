require "test_helper"

class MonkeyParty::AttendeeTest < Test::Unit::TestCase
  context "a monkey party attendee" do
    should "have a hash of subscriptions" do
      assert_kind_of Hash, MonkeyParty::User.monkey_party_subscriptions
      MonkeyParty::User.monkey_party_subscriptions.each do |key, value|
        assert_kind_of MonkeyParty::Attendee::Configuration, value
      end
    end

    should "have a named scope for subscribers" do
      Factory(:user, :subscribes_to_site_news => true)
      users = MonkeyParty::User.users_list_subscribers.find(:all)

      assert !users.empty?
      users.each do |u|
        assert u.subscribes_to_site_news
      end
    end

    should "have a named scope for unsubscribers" do
      Factory(:user, :subscribes_to_site_news => false)
      users = MonkeyParty::User.users_list_nonsubscribers.find(:all)
      assert !users.empty?
      users.each do |u|
        assert !u.subscribes_to_site_news
      end
    end

    should "have a list of subscribing_models" do
      assert !MonkeyParty::Attendee.subscribing_classes.empty?
    end

    should "indicate the the object must be sent to mailchimp upon creation" do
      user = Factory(:user)
      assert_nil user.sent_to_mailchimp_at
    end

    should "have a list of unique fields that are used for subscriptiosn" do
      assert_kind_of Array, MonkeyParty::User.monkey_party_subscription_fields
      assert !MonkeyParty::User.monkey_party_subscription_fields.empty?
    end

    should "indicate the object must be sent to mailchimp when a mailchimp field has been edited" do
      user = Factory(:user, :sent_to_mailchimp_at => Time.now)
      user.login = "somelogin"
      user.save!

      assert_nil user.sent_to_mailchimp_at

    end

    should "not require a mailchimp update if changes aren't on a merge field" do
      user = Factory(:user, :sent_to_mailchimp_at => Time.now)

      user.stubs(:changes).returns({"born_on" => Time.now})
      user.save!

      assert_not_nil user.sent_to_mailchimp_at
    end

    should "have a named scope for records that require a mailchimp update" do
      Factory(:user, :sent_to_mailchimp_at => Time.now)
      new_user = Factory(:user)

      assert MonkeyParty::User.requires_mailchimp_update.find(:all).include?(new_user)
    end
  end

  context "sending to mailchimp" do
    setup do
      MonkeyParty::User.update_all(["sent_to_mailchimp_at = ?", Time.now])
      @subscribed_user = Factory(:user)
      @unsubscribed_user = Factory(:user, :subscribes_to_site_news => false)

      @list = MonkeyParty::List.new(:name => "users")

      @subscribers = [@subscribed_user.to_monkey_party_subscriber]
      @nonsubscribers = [@unsubscribed_user.to_monkey_party_subscriber]

      @list.stubs(:create_subscribers).returns(@subscribers)
      @list.stubs(:destroy_subscribers).returns(@nonsubscribers)

      MonkeyParty::List.stubs(:find_by_name).returns(@list)
    end

    should "issue a find_by_name request for each list" do 
      MonkeyParty::User.monkey_party_subscriptions.each do |name, s|
        MonkeyParty::List.expects(:find_by_name).with(name)
      end

      MonkeyParty::User.send_to_mailchimp
    end

    should "call create subscribers" do
      @list.expects(:create_subscribers).returns(@subscribers)
      MonkeyParty::User.send_to_mailchimp
    end

    should "set the sent_to_mailchimp date when successful" do
      MonkeyParty::User.send_to_mailchimp
      @subscribed_user.reload
      assert_not_nil @subscribed_user.sent_to_mailchimp_at
    end

    should "unsubscribe my record if I opt out" do
      @list.expects(:destroy_subscribers).returns(
        [@unsubscribed_user.to_monkey_party_subscriber])
      MonkeyParty::User.send_to_mailchimp
    end
  end

  context "when transforming to a mailchimp subscriber" do
    setup do
      @user = Factory(:user)
      @subscriber = @user.to_monkey_party_subscriber
    end

    should "have an email" do
      assert_not_nil @subscriber.email
    end

    should "have a merge field for each field" do
      assert !@subscriber.merge_fields.empty?
      assert_equal @subscriber.merge_fields[:login], @user.login
    end
  end

  context "the unsubscribe column" do
    setup do
      @user = Factory(:user, :subscribes_to_site_news => false)
    end

    should "indicate that I'm not subscribed" do
      assert !@user.subscribed_to?("users")
    end
  end

  context "with a has_many option" do
    should "raise an error if the association doesn't exist" do
      pending "error handling"
    end

    should "require an expression" do
      pending "error handling"
    end
    
    should "contain a concatenated list based on the expression" do
      pending "create an associated object"
    end
  end
end

