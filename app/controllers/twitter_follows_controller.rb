class TwitterFollowsController < ApplicationController
  def index
    redirect_to(root_url) && return unless current_user
    @twitter_follows = current_user.twitter_follows.recent
  end

  def unfollow
    @twitter_follow = current_user.twitter_follows.find(params[:id])
    @twitter_follow.unfollow!
    respond_to do |format|
      format.js do
        render inline: "$('#follow-#{@twitter_follow.id}').replaceWith('<%=j render partial: 'twitter_follow', locals: { twitter_follow: @twitter_follow} %>')"
      end
    end
  end
end
