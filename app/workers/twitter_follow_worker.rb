class TwitterFollowWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  SearchResult = Struct.new(:hashtag, :tweet)

  recurrence { hourly.minute_of_hour(0, 10, 20, 30, 40, 50) }

  def perform
    unless ENV['WORKERS_DRY_RUN'].blank?
      puts 'TwitterFollowWorker run but returning due to WORKERS_DRY_RUN env variable'
      return
    end

    User.wants_twitter_follow.find_each do |user|
      begin
        next if !user.twitter_check? || user.rate_limited? || !user.can_twitter_follow? # usernames = []

        follow_prefs = user.twitter_follow_preference
        hashtags = follow_prefs.hashtags.delete('#').delete(' ').split(',').shuffle

        client = begin
                    user.credential.twitter_client
                  rescue
                    nil
                  end
        next if client.nil?

        # Keep track of # of followers user has hourly
        Follower.compose(user) if Follower.can_compose_for?(user)


        search_results = hashtags.flat_map do |hashtag|
          client.search("##{hashtag} exclude:replies exclude:retweets filter:safe",
                        result_type: 'recent', lang: 'en', count: 100)
                .collect
                .take(100)
                .map { |tweet| SearchResult.new(hashtag, tweet) }
        end

        search_results.shuffle.each do |search_result|
          tweet = search_result.tweet
          hashtag = search_result.hashtag

          user_to_follow = tweet.user
          username = user_to_follow.screen_name.to_s
          twitter_user_id = user_to_follow.id

          # Skip users without bio
          next if user_to_follow.default_profile? || user_to_follow.default_profile? || user_to_follow.protected?

          # dont follow people we previously have
          next if TwitterFollow.where(user: user, username: username).any?

          client.friendship_update(username, wants_retweets: false)
          client.mute(username) # don't show their tweets in our feed
          followed = client.follow(username)

          TwitterFollow.follow(user, username, hashtag, twitter_user_id) if followed
        end
      rescue Twitter::Error::TooManyRequests => e
        # rate limited - set rate_limit_until timestamp
        sleep_time = begin
                        (e.rate_limit.reset_in + 1.minute) / 60
                      rescue
                        16
                      end
        follow_prefs.rate_limit_until = DateTime.now + sleep_time.minutes
        follow_prefs.save
      rescue Twitter::Error::Forbidden => e
        if e.message.index('Application cannot perform write actions')
          user.credential.update_attributes(is_valid: false)
        end
      rescue Twitter::Error::Unauthorized => e
        # follow_prefs.update_attributes(mass_follow: false, mass_unfollow: false)
        user.credential.update_attributes(is_valid: false)
        puts "#{user.twitter_username} || #{e}"
      end
    end
  end
end
