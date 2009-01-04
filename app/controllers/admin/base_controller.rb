class Admin::BaseController < ApplicationController
  
  def index
    if current_user && current_user.has_role?('admin')
      redirect_to admin_companies_path
    end
    # Will render default admin/index.html.erb if not an admin
  end
end
