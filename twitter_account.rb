class TwitterAccount
  require 'yaml'
  require 'rubygems'
  require 'twitter'
  require 'net/smtp'
  require 'net/imap'

  attr_accessor :twitter, :home_timeline, :account_name

  def initialize(account_name)
    @file = YAML.load_file('credentials.yml')
    @twitter_credentials = @file['twitter_app']
    @account_name = account_name
    if @account = @file['accounts'][@account_name]
      @most_recent_tweet = @account['most_recent_tweet'] || nil
      @keywords = @account['keywords'] || []
    else
      exit
    end
  end

  def authenticate!
    @twitter = Twitter::REST::Client.new do |config|
      config.consumer_key        = @twitter_credentials['consumer_key']
      config.consumer_secret     = @twitter_credentials['consumer_secret']
      config.access_token        = @account['credentials']['access_token']
      config.access_token_secret = @account['credentials']['access_token_secret']
    end
  end

  def retrieve_home_timeline(options={})
    options['count'] ||= 200
    options['since_id'] ||= @most_recent_tweet if @most_recent_tweet
    options['trim_user'] ||= true
    options['exclude_replies'] ||= true
    options['include_entities'] ||= false
    @home_timeline = @twitter.home_timeline(options)
    exit if @home_timeline.empty?
  end

  def self.analyze_home_timeline(account_name=nil)
    account = new(account_name)
    account.authenticate!
    account.retrieve_home_timeline
    account.update_most_recent_tweet
    account.deliver_tweets(account.keyword_lookup)
  end

  def update_most_recent_tweet
    @file['accounts'][@account_name]['most_recent_tweet'] = @home_timeline.first.id
    File.open('credentials.yml', 'w') {|f| f.write @file.to_yaml }
  end

  def keyword_lookup
    candidates = []
    @home_timeline.each do |tweet|
      @keywords.each { |keyword| candidates << tweet if tweet.text.downcase.include?(keyword) }
    end
    candidates.uniq
  end

  # move to new mailbox class https://github.com/mikel/mail#sending-an-email
  def deliver_tweets(tweets=nil)
    exit unless tweets
    chained_tweets = ""
    tweets.each {|tweet| chained_tweets += "#{tweet.id} #{tweet.text} \n"}
    msg = "Subject: New tweets on #{Time.now} for #{@account_name}\n\n#{chained_tweets}"
    smtp = Net::SMTP.new 'smtp.gmail.com', 587
    smtp.enable_starttls
    smtp.start("gmail.com", @account['credentials']['email_address'], @account['credentials']['email_password'], :login) do
      smtp.send_message(msg, @account['credentials']['email_address'], @account['deliver_to'])
    end
  end

  def self.check_inbox_and_retweet(account_name=nil)
    account = new(account_name)
    account.retrieve_tweet_ids
    # retweet(retrieve_tweet_ids)
  end

  # move to new mailbox class https://github.com/mikel/mail#getting-emails-from-a-pop-server
  def retrieve_tweet_ids
    imap = Net::IMAP.new('imap.gmail.com', 993, true, nil, false)
    imap.login(@account['credentials']['email_address'], @account['credentials']['email_password'])
    imap.select('INBOX')
    imap.search(["NOT","SEEN"]).each do |message_id|
      msg = imap.fetch(message_id, 'RFC822')[0].attr['RFC822']
      # imap.store(message_id, '+FLAGS', [:Seen])
puts msg
    end 
    imap.logout()
    imap.disconnect()
  end
end

# require "./twitter_account"
# TwitterAccount.analyze_home_timeline('flotilla_aerea')
# TwitterAccount.check_inbox_and_retweet('flotilla_aerea')