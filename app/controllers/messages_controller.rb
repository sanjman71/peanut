class MessagesController < ApplicationController

  privilege_required    'manage site', :only => [:index]

  # GET /messages
  def index
    @messages = Message.all(:include => [:message_recipients, :sender], :order => 'updated_at desc').paginate(:page => params[:page], :per_page => 50)

    respond_to do |format|
      format.html
    end
  end
  
  # GET /messages/new
  def new
    respond_to do |format|
      format.html
    end
  end
  
  # POST /messages
  def create
    Message.transaction do
      @address  = params[:message].delete("address")
      @message  = Message.create(params[:message])
    
      if @address
        # map address to a messable
        @messagable = EmailAddress.find_by_address(@address)
      end
    
      if @message.valid? and @messagable
        # add messagable
        @message.message_recipients.create(:messagable => @messagable, :protocol => @messagable.protocol)
      end

      logger.debug("*** referer: #{request.referer}")

      if @message.valid? and @message.message_recipients.size == 0
        # not allowed to have a message with no recipients
        flash[:error] = "Message has no recipients"
        raise ActiveRecord::Rollback
      end

      if @message.valid?
        # send message
        @message.send!
        flash[:notice] = "Message sent"
        @redirect_path = request.referer
      else
        flash[:error]  = "There was an error sending the message"
        @redirect_path = request.referer
      end
    end # transaction

    @redirect_path ||= messages_path

    respond_to do |format|
      format.html { redirect_to(@redirect_path) }
      format.js { render(:update) { |page| page.redirect_to(@redirect_path) } }
    end
  end
  
end