class PhoneNumbersController < ApplicationController
  before_filter :init_user, :only => [:promote, :destroy]

  privilege_required      'update users', :only => [:promote, :destroy], :on => :user

  # GET /users/1/phone/3/promote
  def promote
    @phone = @user.phone_numbers.find(params[:id])
    # mark phone as highest priority
    @phone.update_attribute(:priority, PhoneNumber::PRIORITY_HIGHEST)
    # lower priorities on all other phone numbers
    current_user.phone_numbers.select{ |o| o != @phone }.each{ |o| o.update_attribute(:priority, PhoneNumber::PRIORITY_MEDIUM)}

    flash[:notice] = "Changed primary phone number to #{@phone.address}"
    redirect_to(user_edit_path(@user)) and return
  end

  # DELETE /users/1/phone/3
  def destroy
    @phone = @user.phone_numbers.find(params[:id])
    @user.phone_numbers.destroy(@phone)

    flash[:notice] = "Removed phone number #{@phone.address}"
    redirect_to(user_edit_path(@user)) and return
  end

  protected

  def init_user
    @user = User.find(params[:user_id])
  end
  
end