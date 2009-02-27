class PlansController < ApplicationController

  layout 'home'

  def index
    @plans = Plan.all
  end
  
  def show
    @plan = Plan.find(params[:id])
  end

end
