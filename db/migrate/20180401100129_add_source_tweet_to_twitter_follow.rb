class AddSourceTweetToTwitterFollow < ActiveRecord::Migration[5.1]
  def change
    add_column :twitter_follows, :source_tweet_uri, :string
    add_column :twitter_follows, :source_tweet_text, :text
  end
end
