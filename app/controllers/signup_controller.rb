class SignupController < ApplicationController
  layout 'signup'

  # /signup/:plan
  def new
    @domain = '.peanutcalendar.com'
    
    if request.post? or request.put?
      @user     = User.new(params[:company].delete(:user))
      @terms    = params[:company].delete(:terms).to_i
      @company  = Company.new(params[:company])
      
      # use a transaction to objects
      Company.transaction do
        # check terms
        @terms_error = 'Please accept the terms and conditions' unless @terms == 1
        
        # create company, user objects
        @company.save
        @user.company = @company
        @user.save
        
        # rollback unless all objects are valid
        raise ActiveRecord::Rollback if !@company.valid? or !@user.valid? or @terms != 1

        # signup completed
        redirect_to companies_path
      end
    else
      @company  = Company.new
      @user     = User.new
    end
  end
  
end