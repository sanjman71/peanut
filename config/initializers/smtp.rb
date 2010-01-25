ActionMailer::Base.smtp_settings = {
  :tls => true,
  :address => "smtp.gmail.com",
  :port => "587",
  :authentication => :plain,
  :domain => "walnutindustries.com",
  :user_name => "messaging@walnutindustries.com",
  :password => "1ndus7ry!"
}
