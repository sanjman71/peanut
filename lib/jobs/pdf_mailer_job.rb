require 'mechanize'

class PdfMailerJob < Struct.new(:params)
  def self.priority
    1
  end

  def pdf_dir
    "#{RAILS_ROOT}/pdf"
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

    url = params[:url]

    if url.blank?
      logger.debug("#{Time.now}: [pdf mailer error] no url")
      return
    end

    if url.match(/.email/)
      # get url that generates an email
      get(url)
    elsif url.match(/.pdf/)
      # get url that generates a pdf
      address = params[:address]
      subject = params[:subject] || 'Your PDF Schedule'
      body    = params[:body] || "Your schedule is attached."
      get_pdf(url, address, subject, body)
      # cleanup old pdf files
      cleanup_pdf_files
    else
      logger.debug("#{Time.now}: [pdf mailer error] invalid url #{url}")
      return
    end
  end

  def get(url)
    # get url
    agent = WWW::Mechanize.new
    agent.get(url)
  end

  def get_pdf(url, address, subject, body)
    # get pdf from specified url
    agent = WWW::Mechanize.new
    agent.get(url)

    # validate content type
    if agent.page.response["content-type"] != "application/pdf; charset=utf-8"
      logger.debug("#{Time.now}: [pdf mailer error] content type is not application/pdf")
      return
    end

    # create pdf directory
    system "mkdir -p #{pdf_dir}"
    # create pdf file
    timestamp = Time.now.strftime("%Y%m%d%H%M%S")
    file      = "#{pdf_dir}/schedule.%s.pdf" % timestamp
    File.open(file, 'wb') { |o| o << agent.page.body }

    begin
      # send email
      PdfMailer.deliver_email(address, subject, body, file)
    rescue Exception => e
      logger.debug("#{Time.now}: [pdf mailer exception] #{e.message}")
    ensure
      # pdf files are cleaned up after the message is sent
    end
  end

  def cleanup_pdf_files
    dir       = Dir.new(pdf_dir)
    pdf_files = dir.entries[2..-1].sort # remove '.', '..' entries

    pdf_files.each do |file_name|
      mod_time = File.new("#{pdf_dir}/#{file_name}").atime
      if mod_time < (Time.now - 1.hour)
        FileUtils.rm_rf(File.join(pdf_dir, file_name))
        logger.debug("#{Time.now}: [pdf mailer] cleanup, deleted file #{file_name}")
      end
    end
  end

end