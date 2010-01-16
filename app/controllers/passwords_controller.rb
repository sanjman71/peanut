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
    @user   = User.with_email(@email).first

    if @user.blank?
      flash[:error] = "Invalid email address"
      redirect_to(password_forgot_path) and return
    end

    # reset user's password with a random one
    @password = User.generate_password(10)
    @user.password = @password
    @user.password_confirmation = @password
    @user.save

    # send user the new password
    MessageComposeUser.password_reset(@user, @password)

    flash[:notice] = "A new password will be sent to #{@email}"

    # set redirect path based on authenticated flag
    if logged_in?
      # user is logged in, redirect to referer
      @redirect_path = request.referer
    else
      # user is a guest, redirect to login path
      @redirect_path = login_path
    end

    respond_to do |format|
      format.html { redirect_to(@redirect_path) and return }
      format.js { render(:update) { |page| page.redirect_to(@redirect_path) } }
    end
  end

end