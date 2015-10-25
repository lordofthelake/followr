class Credential < ActiveRecord::Base
	belongs_to :user

	validates_presence_of :user
  validates_presence_of :twitter_oauth_token
  validates_presence_of :twitter_oauth_token_secret
  validates_presence_of :twitter_consumer_key
  validates_presence_of :twitter_consumer_secret

  attr_encrypted :twitter_oauth_token, :key => ENV['APPLICATION_SECRET_KEY']
  attr_encrypted :twitter_oauth_token_secret, :key => ENV['APPLICATION_SECRET_KEY']
  attr_encrypted :twitter_consumer_key, :key => ENV['APPLICATION_SECRET_KEY']
  attr_encrypted :twitter_consumer_secret, :key => ENV['APPLICATION_SECRET_KEY']


  scope :valid, -> { where('is_valid IS TRUE') }
  scope :not_valid, -> { where('is_valid IS NOT TRUE')}
  scope :valid_for_follow, -> { valid.where('rate_limit_until IS NULL OR rate_limit_until < ?', DateTime.now) }

  MAX_TWITTER_APPS = 4 # allow user to have multiple credentials tied to different twitter applications

  def self.create_with_omniauth(user, params)
    if params[:twitter_oauth_token]
      cr = Credential.select { |c| c.twitter_oauth_token == params[:twitter_oauth_token] }.first rescue nil
      cr = Credential.new if cr.nil?
      cr.user ||= user
      cr.twitter_consumer_key = params[:twitter_consumer_key]
      cr.twitter_consumer_secret = params[:twitter_consumer_secret]
      cr.twitter_oauth_token = params[:twitter_oauth_token]
      cr.twitter_oauth_token_secret = params[:twitter_oauth_token_secret]
      cr.app_id = params[:followr_app_id]
    else
      twitter_oauth_token = params[:auth]["extra"]["access_token"].params[:oauth_token]
      twitter_oauth_token_secret = params[:auth]["extra"]["access_token"].params[:oauth_token_secret]
      cr = Credential.select { |c| c.twitter_oauth_token == twitter_oauth_token }.first rescue nil
      cr = Credential.new unless cr
      cr.user ||= user
      cr.twitter_oauth_token = twitter_oauth_token
      cr.twitter_oauth_token_secret = twitter_oauth_token_secret
    end
    cr.save! if cr.changed?
    cr
  end

	def twitter_client
    return nil if [twitter_oauth_token, twitter_oauth_token_secret].include?(nil)
    valid_client = nil
    begin
      client = Twitter::REST::Client.new do |c|
        c.consumer_key        = twitter_consumer_key.present? ? twitter_consumer_key : ENV['TWITTER_CONSUMER_KEY']
        c.consumer_secret     = twitter_consumer_secret ? twitter_consumer_secret : ENV['TWITTER_CONSUMER_SECRET']
        c.access_token        = twitter_oauth_token
        c.access_token_secret = twitter_oauth_token_secret
      end

      # test to see if credential is valid -- not rate limited
      client.remove_list_member('-this will do nothing-')
    rescue Twitter::Error::BadRequest => e
      valid_client = client
    rescue Twitter::Error::Unauthorized => e
      self.update_column(:is_valid, :false)
    ensure
      return valid_client
    end

    return valid_client
	end
  
end
