class EmailAddressesController < ApplicationController
  before_filter :init_user, :only => [:promote, :destroy]

  privilege_required      'update users', :only => [:promote, :destroy], :on => :user

  # GET /users/1/email/3/promote
  def promote
    @email = @user.email_addresses.find(params[:id])
    # mark email as highest priority
    @email.update_attribute(:priority, EmailAddress::PRIORITY_HIGHEST)
    # lower priorities on all other email addresses
    current_user.email_addresses.select{ |o| o != @email }.each{ |o| o.update_attribute(:priority, EmailAddress::PRIORITY_MEDIUM)}

    flash[:notice] = "Changed primary email address to #{@email.address}"
    redirect_to(user_edit_path(@user)) and return
  end

  # DELETE /users/1/email/3
  def destroy
    @email = @user.email_addresses.find(params[:id])
    @user.email_addresses.destroy(@email)

    flash[:notice] = "Removed email address #{@email.address}"
    redirect_to(user_edit_path(@user)) and return
  end

  protected
  
  def init_user
    @user = User.find(params[:user_id])
  end
  
end