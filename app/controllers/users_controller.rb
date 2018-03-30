class UsersController < ApplicationController

  def update
    begin
      u = User.find current_user.id
      u.email = params[:user][:email].downcase
      u.save!
    ensure
      redirect_to dashboard_path
    end
  end

  def unfollow
    begin
      @twitter_follow = current_user.twitter_follows.find(params[:id])
      @twitter_follow.unfollow!
      respond_to do |format|
        format.js { render inline: "$('#follow-#{@twitter_follow.id}').replaceWith('<%=j render partial: 'twitter_follow', locals: { twitter_follow: @twitter_follow} %>')" }
      end

    rescue => e
      render js: "alert('Oops! It seems that something went wrong :(')"
    end
  end
end
