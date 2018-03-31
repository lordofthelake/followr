class AddWasFollowingToTwitterFollow < ActiveRecord::Migration[5.1]
  def change
    add_column :twitter_follows, :was_following, :boolean
  end
end
