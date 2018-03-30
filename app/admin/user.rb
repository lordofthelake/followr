ActiveAdmin.register User do
  controller do
    def find_resource
      User.find_by_id(params[:id])
    end
  end

  filter :twitter_username
  filter :created_at

  index do
    selectable_column
    id_column

    column :name
    column (:twitter_username) { |u| link_to u.twitter_username, "https://twitter.com/#{u.twitter_username}", target: '_blank' }
    column :twitter_check?
    column (:hashtags) { |u| u.hashtags.join(',') }
    column ('Followers Increase') do |u|
      begin
        u.followers.last.count - u.followers.first.count
      rescue
        nil
      end
    end
    column :created_at
    actions
  end
end
