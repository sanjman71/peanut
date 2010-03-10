class HomeController < ApplicationController

  layout 'home'
  
  def index
    if current_company
      # show company home page
      if mobile_device?
        render(:action => :index, :layout => 'company') and return
      else
        redirect_to openings_path(:subdomain => current_subdomain) and return
      end
    else
      # show www/root home page
      render(:action => :index, :layout => 'home') and return
    end
  end

  # POST /tryit
  def tryit
    # extract name and email
    @name     = params[:name]
    @email    = params[:email]

    # find site admins, and their primary emails
    @admins   = User.with_role(Badges::Role.find_by_name('admin'))
    @emails   = @admins.collect{ |o| o.primary_email_address }

    # raise Exception, "sending emails to #{@emails.collect(&:address).join(',')}"

    @sender   = @admins.first
    @subject  = "Beta signup interest"
    @body     = "Name: #{@name}, Email: #{@email} is interested in signing up for the beta."

    begin
      @message  = MessageCompose.send(@sender, @subject, @body, @emails, nil, nil)
    rescue

    end

    flash[:notice] = "Thanks for signing up.  We will contact you shortly."

    redirect_to("/") and return
  end

  # Handle all unauthorized access redirects
  def unauthorized
    if @current_company
      layout = 'company'
    else
      layout = 'home'
    end
    
    render :action => :unauthorized, :layout => layout
  end
  
  def faq
    respond_to do |format|
      format.html
    end
  end
  
  def demos
    respond_to do |format|
      format.html
    end
  end
  
end
