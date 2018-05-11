namespace :twitter do
  task purge: :environment do
    next if TwitterFollow.count < 9000
    TwitterFollow.where(id: TwitterFollow.where.not(unfollowed_at: nil).order(:created_at).limit(1000)).delete_all
  end
end
