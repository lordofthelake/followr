class TwitterFollow < ActiveRecord::Base
  belongs_to :user
  validates_presence_of :username
  validates_uniqueness_of :user_id, scope: :username

  scope :recent, ->(limit = 200) { order('created_at desc').limit(limit) }

  def self.follow!(user, search_result, hashtag)
    origin_tweet = search_result.tweet
    twitter_user = search_result.user

    TwitterFollow.create!(
      user: user,
      username: twitter_user.screen_name.to_s,
      followed_at: DateTime.now,
      hashtag: hashtag,
      twitter_user_id: twitter_user.id,
      followers_count: twitter_user.followers_count,
      following_count: twitter_user.friends_count,
      statuses_count: twitter_user.statuses_count,
      favourites_count: twitter_user.favourites_count,
      lang: twitter_user.lang,
      description: twitter_user.description,
      source_tweet_text: origin_tweet.text,
      source_tweet_uri: origin_tweet.uri
    )
  end

  def unfollow!
    return if unfollowed
    client = begin
             user.credential.twitter_client
           rescue
             nil
           end
    client.unfollow(username)
    client.unmute(username)
    update_attributes!(unfollowed: true, unfollowed_at: DateTime.now)
  end
end
