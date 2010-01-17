class MessagesController < ApplicationController

  privilege_required    'manage site', :only => [:index]

  @@per_page  = 25

  # GET /messages
  def index
    @messages = current_company.messages.all(:include => [:message_recipients, :sender], :order => 'messages.updated_at desc').paginate(:page => params[:page], :per_page => @@per_page)

    # messages by protocol
    @msgs_by_protocol = MessageRecipient.protocols.inject(Hash[]) do |hash, protocol|
      hash[protocol]  = CompanyMessageDelivery.for_company(current_company).for_protocol(protocol).count
      hash
    end
    @total_count      = @msgs_by_protocol.values.inject(0) { |sum, i| sum += i }

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
    @sender_id  = params[:message][:sender_id]
    # use sender_id if specified, default to current user
    @sender     = @sender_id ? User.find(@sender_id) : current_user
    @subject    = params[:message][:subject]
    @body       = params[:message][:body]
    @address    = params[:message][:address]
    @recipients = []
    # topic is current company, default to sender
    @topic      = current_company || @sender
    @tag        = 'message'

    # map address to a messagable
    if @address
      # map address to a messable
      @messagable = EmailAddress.find_by_address(@address)
      @recipients.push(@messagable) if @messagable
    end
    
    if @recipients.empty?
      # message must have at least 1 recipient
      flash[:error] = "Message has no recipients"
    else
      @message = MessageCompose.send(@sender, @subject, @body, @recipients, @topic, @tag)

      if @message
        flash[:notice] = "Message sent"
        @redirect_path = request.referer
      else
        flash[:error]  = "There was an error sending the message"
        @redirect_path = request.referer
      end
    end
    
    @redirect_path ||= messages_path

    respond_to do |format|
      format.html { redirect_to(@redirect_path) }
      format.js { render(:update) { |page| page.redirect_to(@redirect_path) } }
    end
  end
  
end