class User < ActiveRecord::Base
  default_scope -> { includes(:credential, :twitter_follow_preference) }

  has_many :twitter_follows
  has_many :followers

  has_many :credential, dependent: :destroy
  has_one :twitter_follow_preference, dependent: :destroy

  scope :wants_twitter_follow, -> { joins('INNER JOIN twitter_follow_preferences ON (users.id = user_id)').where('twitter_follow_preferences.mass_follow IS TRUE') }
  scope :wants_twitter_unfollow, -> { joins('INNER JOIN twitter_follow_preferences ON (users.id = user_id)').where('twitter_follow_preferences.mass_unfollow IS TRUE') }

  after_create :init_follow_prefs

  def self.create_with_omniauth(auth)
    create! do |user|
      user.twitter_uid = auth["uid"]
      user.twitter_username = auth["info"]['nickname']
      user.name = auth["info"]["name"]
    end
  end

  def init_follow_prefs
    self.twitter_follow_preference = TwitterFollowPreference.new(user: self)
  end

  def rate_limited?
    credential.valid_for_follow.empty?
  end

  # true if all is good to start following
  def twitter_check?
    follow_prefs = self.twitter_follow_preference
    hashtags = follow_prefs.hashtags.gsub('#','').split(',')

    client = credential.valid.first.twitter_client rescue nil
    return false if client.nil? || hashtags.empty? || (!follow_prefs.want_mass_follow? && !follow_prefs.mass_unfollow)
    true
  end

  def can_twitter_follow?
    return false if credential.valid_for_follow.empty? || rate_limited?
    true
  end

  def can_twitter_unfollow?
    return false unless self.credential.is_valid

    unfollowed_in_last_hour = self.twitter_follows.where('unfollowed_at > ?', 1.hour.ago)
    unfollowed_in_last_day = self.twitter_follows.where('unfollowed_at > ?', 24.hours.ago)
    return false if unfollowed_in_last_hour.count >= 50 || unfollowed_in_last_day.count >= 900
    true
  end

  def began_following_users
    twitter_follows.first.created_at.to_date rescue nil
  end

  def hashtags
    twitter_follow_preference.hashtags.gsub('#','').gsub(' ','').split(',') rescue []
  end

  def self.send_reauth_email
    users = [User.wants_twitter_follow, User.wants_twitter_unfollow].flatten.uniq { |l| l.email }
    users.each do |user|
      next unless user.email.present?
      UserMailer.reauthentication_notification(user).deliver_later
    end
  end

end
