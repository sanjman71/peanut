class LogEntriesController < ApplicationController

  # Everyone can create an log_entry, though they generally won't know it.
  privilege_required  'read log_entries', :only => [:index]
  privilege_required  'update log_entries', :only => [:mark_as_seen]
  privilege_required  'create log_entries', :only => [:create]
  privilege_required  'delete log_entries', :only => [:destroy]

  def index
    if params[:state].blank? || params[:state] == 'unseen'
      @seen = false
      @urgent = current_company.log_entries.urgent.unseen.order_recent.paginate(:page => params[:urgent_page])
      @approval = current_company.log_entries.approval.unseen.order_recent.paginate(:page => params[:approval_page])
      @informational = current_company.log_entries.informational.unseen.order_recent.paginate(:page => params[:info_page])
    else
      @seen = true
      @urgent = current_company.log_entries.urgent.seen.order_recent.paginate(:page => params[:urgent_page])
      @approval = current_company.log_entries.approval.seen.order_recent.paginate(:page => params[:approval_page])
      @informational = current_company.log_entries.informational.seen.order_recent.paginate(:page => params[:info_page])
    end

    respond_to do |format|
      format.html
    end
  end
  
  def mark_as_seen
    @log_entry = LogEntry.find(params[:id])
    if @log_entry
      if (params[:seen].blank? || params[:seen] == true)
        @log_entry.mark_as_seen!
        state = :unseen
      else
        @log_entry.mark_as_unseen!
        state = :seen
      end
    end
    if @log_entry.save
      flash[:notice] = "Changed Log Entry"  
    else
      flash[:error] = "Couldn't change Log Entry"
    end
    
    respond_to do |format|
      format.html { 
        redirect_to url_for(:subdomain => current_subdomain, :action => 'index', :state => state.to_s) and return }
      format.js {
        if state == :seen
          @urgent_by_day = current_company.log_entries.urgent.seen.order_recent.group_by { |e| e.updated_at.beginning_of_day }
          @approval_by_day = current_company.log_entries.approval.seen.order_recent.group_by { |e| e.updated_at.beginning_of_day }
          @informational_by_day = current_company.log_entries.informational.seen.order_recent.group_by { |e| e.updated_at.beginning_of_day }
        else
          @urgent_by_day = current_company.log_entries.urgent.unseen.order_recent.group_by { |e| e.updated_at.beginning_of_day }
          @approval_by_day = current_company.log_entries.approval.unseen.order_recent.group_by { |e| e.updated_at.beginning_of_day }
          @informational_by_day = current_company.log_entries.informational.unseen.order_recent.group_by { |e| e.updated_at.beginning_of_day }
        end
      }
    end
    
  end
  
  def create
    e = LogEntry.new(params[:log_entry])
    e.company_id = current_company.id unless current_company.blank?
    e.user_id = current_user.id unless current_user.blank?
    if e.save
      flash[:notice] = "Your Log Entry was created"
    else
      flash[:error] = "Problem creating Log Entry"
    end
    
    redirect_to log_entries_path(:subdomain => current_subdomain) and return
  end
  
  def destroy
    @log_entry = LogEntry.find(params[:id])
    
    if @log_entry && @log_entry.delete
      flash[:notice] = "Log Entry was deleted"
    else
      flash[:error] = "Couldn't delete Log Entry"
    end
    @urgent = current_company.log_entries.urgent
    @approval = current_company.log_entries.approval
    @informational = current_company.log_entries.informational
    
    respond_to do |format|
      format.html { redirect_to log_entries_path(:subdomain => current_subdomain)}
      format.js
    end
  end
  
end
