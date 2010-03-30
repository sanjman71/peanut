class VacationsController < ApplicationController

  # GET /vacations
  # GET /users/1/vacations
  def index
    @provider = init_provider(:default => nil)
    
    if @provider
      # find provider vacations
      @vacations = @provider.provided_appointments.vacation
    else
      # find company vacations
      @vacations = current_company.appointments.vacation.no_provider
    end

    respond_to do |format|
      format.html
    end
  end

  # POST /vacation
  # POST /users/1/vacation
  def create
    @provider = init_provider(:default => nil)

    @start_at = Time.zone.parse(params[:start_date]).beginning_of_day
    @end_at   = Time.zone.parse(params[:end_date]).end_of_day
    @mark_as  = Appointment::VACATION

    if @provider
      # provider vacation
      @vacation = current_company.appointments.create(:provider => @provider, :start_at => @start_at, :end_at => @end_at, :mark_as => @mark_as)
    else
      # company vacation
      @vacation = current_company.appointments.create(:start_at => @start_at, :end_at => @end_at, :mark_as => @mark_as)
    end

    if @vacation.valid?
      flash[:notice] = "Vacation schedule added"
    else
      flash[:error] = "Vacation schedule could not be added"
    end

    if @provider
      @redirect_path = provider_vacations_path
    else
      @redirect_path = company_vacations_path
    end

    respond_to do |format|
      format.html { redirect_to(@redirect_path) and return }
      format.js { render(:update) { |page| page.redirect_to(@redirect_path) } }
    end
  end

  # DELETE /users/1/vacation/5
  def destroy
    @provider = init_provider(:default => nil)
    @vacation = current_company.appointments.find(params[:id])
    @vacation.destroy

    flash[:notice] = "Vacation schedule deleted"

    if @provider
      # redirect to provider vacations index
      @redirect_path = provider_vacations_path
    else
      # redirect to company vacations index
      @redirect_path = company_vacations_path
    end

    respond_to do |format|
      format.html { redirect_to(@redirect_path) and return }
      format.js { render(:update) { |page| page.redirect_to(@redirect_path) } }
    end
  end

end