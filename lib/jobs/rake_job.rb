class RakeJob < Struct.new(:params)

  def logger
    case RAILS_ENV
    when 'development'
      @logger ||= Logger.new(STDOUT)
    else
      @logger ||= Logger.new("log/rake.log")
    end
  end

  def perform
    logger.info "#{Time.now}: [rake] #{params.inspect}"
    system "bash -ic '#{params[:cmd]}'"
    logger.info "#{Time.now}: [rake] completed"
  end

end