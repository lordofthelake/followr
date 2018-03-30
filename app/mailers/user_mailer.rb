class UserMailer < ActionMailer::Base
  default from: 'Followr <no-reply@followr.club>'

  def reauthentication_notification(user)
    @name = user.name || user.twitter_username
    mail(to: user.read_attribute(:email), subject: 'Time to reauthenticate yourself') if user.email
  end
end
