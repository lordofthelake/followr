class MoveRateLimitUntilToCredential < ActiveRecord::Migration
  def change
    remove_column :twitter_follow_preferences, :rate_limit_until, :datetime
    add_column :credentials, :rate_limit_until, :datetime
  end
end
