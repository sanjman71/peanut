ActionMailer::Base.smtp_settings = {
  :tls => true,
  :address => "smtp.gmail.com",
  :port => "587",
  :authentication => :plain,
  :user_name => "peanut@jarna.com",
  :password => "peanut4all" 
}
