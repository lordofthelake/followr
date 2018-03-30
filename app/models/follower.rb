class Follower < ActiveRecord::Base

  belongs_to :user

	def self.compose(user)
    client = user.credential.twitter_client rescue nil
    followers_count = client.follower_ids.count rescue nil

    return if client.nil? || followers_count.nil?

    followers = user.followers

    options = {
      :source => 'twitter',
      :count => followers_count,
      :user => user
    }

    followers << Follower.new(options)

	end

  def self.can_compose_for?(user)
    last_entry = user.followers.order('created_at DESC').first rescue nil
    return false if last_entry.present? && last_entry.created_at.to_datetime.in_time_zone(Rails.application.config.time_zone).hour == DateTime.now.in_time_zone(Rails.application.config.time_zone).hour
    true
  end
end