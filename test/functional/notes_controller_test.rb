require 'test/test_helper'

class NotesControllerTest < ActionController::TestCase

  should_route :post, '/notes', :controller => 'notes', :action => 'create'

  def setup
    # initialize roles and privileges
    BadgesInit.roles_privileges

    @owner          = Factory(:user, :name => "Owner")
    @monthly_plan   = Factory(:monthly_plan)
    @subscription   = Subscription.new(:user => @owner, :plan => @monthly_plan)
    @company        = Factory(:company, :subscription => @subscription)
    @anywhere       = Location.anywhere
    @provider       = Factory(:user, :name => "Provider")
    @company.user_providers.push(@provider)
    @company.reload
    @work_service   = Factory.build(:work_service, :name => "Work service", :price => 1.00)
    @company.services.push(@work_service)
    @work_service.user_providers.push(@provider)
    @free_service   = @company.free_service
    @customer       = Factory(:user, :name => "Customer")

    # stub current company
    @controller.stubs(:current_company).returns(@company)
    @controller.stubs(:current_user).returns(nil)

    @tomorrow          = Time.zone.now.tomorrow.to_s(:appt_schedule_day) # e.g. 20081201
    @time_range        = TimeRange.new({:day => @tomorrow, :start_at => "1000", :end_at => "1300"})
    @date_time_options = {:start_at => @time_range.start_at}
    @options           = {:force => true}
    @work_appt         = AppointmentScheduler.create_work_appointment(@company, Location.anywhere, @provider, @work_service, 
@work_service.duration, @customer, @provider, @date_time_options, @options)
  end

  context "add note to work appointment" do
    setup do
      post :create, :note => {:subject_id => @work_appt.id, :subject_type => @work_appt.class.to_s, :comment => "This is a note attached to a comment"}
    end
    
    should_respond_with :success
    should_set_the_flash_to /Added note/i
    should_not_change("message count") { Message.count }
    
  end

end