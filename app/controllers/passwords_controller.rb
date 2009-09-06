class PasswordsController < ApplicationController

  # GET /password/forgot
  def forgot
    respond_to do |format|
      format.html
    end
  end

  # POST /password/reset
  def reset
    @email  = params[:email]
    @user   = User.find_by_email(@email)

    if @user.blank?
      flash[:error] = "Could not find the specified email address"
      redirect_to(password_forgot_path) and return
    end

    @user = User.create_or_reset_with_random_password(@email)
    flash[:notice] = "Your new password will be sent to #{@email}"
    redirect_to(login_path) and return
  end
end