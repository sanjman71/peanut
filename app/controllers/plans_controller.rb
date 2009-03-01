class PlansController < ApplicationController

  layout 'home'
  
  privilege_required 'create plans', :only => [:new, :create]
  privilege_required 'read plans', :only => [:index, :show]
  privilege_required 'update plans', :only => [:edit, :update]
  privilege_required 'delete plans', :only => [:destroy]

  def new
    @plan = Plan.new
  end
  
  def create
  end
  
  def index
    @plans = Plan.order_by_cost
  end
  
  def show
    @plan = Plan.find(params[:id])
  end
  
  def edit
    @plan = Plan.find(params[:id])
  end
  
  def update
    @plan = Plan.find(params[:id])
  end
  
  def destroy
  end

end
