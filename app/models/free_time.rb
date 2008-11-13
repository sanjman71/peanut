class FreeTime
  attr_accessor :day, :start_at, :end_at, :job, :resource_id, :company_id
  
  def initialize(options={})
    @day          = options[:day]
    @start_at     = options[:start_at]
    @end_at       = options[:end_at]
    @resource_id  = options[:resource_id]
    @company_id   = options[:company_id]
    @customer_id  = options[:customer_id]
    @job          = Job.free.first
    
    if @start_at.is_a?(String) and @day and @day.is_a?(String)
      # convert day to time object, build start_at using chronic
      @start_at = Chronic.parse(@start_at, :now => Time.parse(@day))
    end

    if @end_at.is_a?(String) and @day and @day.is_a?(String)
      # convert day to time object, build end_at using chronic
      @end_at = Chronic.parse(@end_at, :now => Time.parse(@day))
    end
  end
  
  def resource
    Resource.find_by_id(@resource_id)
  end
  
  def to_s
    @id.to_s
  end
  
  # build appointment from free time object
  def to_appointment
    Appointment.new(:company_id => @company_id, :customer_id => @customer_id, :job_id => @job.id, :resource_id => @resource_id,
                    :start_at => @start_at, :end_at => @end_at)
  end
  
end