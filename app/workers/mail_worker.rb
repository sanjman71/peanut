class MailWorker < Workling::Base
  
  def test(options)
    logger.debug("*** workling test method")
  end
  
end