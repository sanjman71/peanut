class SignupController < ApplicationController
  layout 'home'
  # ssl_required :new
  
  # /signup/:plan
  def new
    if request.post? or request.put?
      @user     = User.new(params[:user])
      @terms    = params[:company].delete(:terms).to_i
      @company  = Company.new(params[:company])
      
      # use a transaction to objects
      Company.transaction do
        # check terms
        @terms_error = 'The terms and conditions must be accepted' unless @terms == 1
        
        # create company, user objects
        @company.save
        @user.save
        
        # rollback unless all objects are valid
        raise ActiveRecord::Rollback if !@company.valid? or !@user.valid? or @terms != 1

        # register, activate user
        @user.register!
        @user.activate!
        
        # set user roles
        @user.grant_role('company manager')
        
        # signup completed, redirect to login page
        flash[:notice] = "Signup complete! Please sign in to continue."
        return redirect_to(login_path(:subdomain => @company.subdomain))
      end
    else
      @company  = Company.new
      @user     = User.new
    end
  end
  
end