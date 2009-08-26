class PromotionsController < ApplicationController
  layout 'home'

  privilege_required 'manage site'

  # GET /promotions
  def index
    @promotions = Promotion.paginate(:page => params[:page], :per_page => 100, :order => 'code asc')

    respond_to do |format|
      format.html
    end
  end

  # GET /promotions/new
  def new
    @promotion = Promotion.new

    respond_to do |format|
      format.html
    end
  end
  
  # POST /promotions
  def create
    @promotion = Promotion.create(params[:promotion])
    
    if @promotion.valid?
      flash[:notice] = "Promotion #{@promotion.code} created"
      redirect_to(promotions_path)
    else
      render(:action => 'new')
    end
  end
end