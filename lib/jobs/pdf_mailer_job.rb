require 'mechanize'

class PdfMailerJob < Struct.new(:params)
  def self.priority
    1
  end

  def logger
    case RAILS_ENV
    when 'development'
      @logger ||= Logger.new(STDOUT)
    else
      @logger ||= Logger.new("log/messages.log")
    end
  end

  def perform
    logger.info("#{Time.now}: [pdf mailer] new job: #{params.inspect}")

    address = params[:address]
    file    = params[:file]
    url     = params[:url]
    subject = params[:subject] || 'Your PDF Schedule'
    body    = params[:body] || "Your schedule is attached."

    if address.blank?
      logger.debug("#{Time.now}: [pdf mailer error] no address")
      return
    end

    if file.blank? and url.blank?
      logger.debug("#{Time.now}: [pdf mailer error] no file or url")
      return
    end

    if !url.blank?
      # get pdf from specified url
      agent = WWW::Mechanize.new
      agent.get(url)
      # validate content type
      if agent.page.response["content-type"] != "application/pdf; charset=utf-8"
        logger.debug("#{Time.now}: [pdf mailer error] content type is not application/pdf")
        return
      end
      # create pdf directory
      pdf_dir   = "#{RAILS_ROOT}/pdf"
      system "mkdir -p #{pdf_dir}"
      # create pdf file
      timestamp = Time.now.strftime("%Y%m%d%H%M%S")
      file      = "#{pdf_dir}/schedule.%s.pdf" % timestamp
      File.open(file, 'wb') { |o| o << agent.page.body }
    end

    begin
      # send email
      PdfMailer.deliver_email(address, subject, body, file)
    rescue Exception => e
      logger.debug("#{Time.now}: [pdf mailer exception] #{e.message}")
      return
    end

    # delete pdf file
    # File.delete(file) if File.exists(file)
  end

end