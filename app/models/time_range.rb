class TimeRange
  attr_accessor :day, :start_at, :end_at
  
  def initialize(options={})
    @day          = options[:day]
    @start_at     = options[:start_at]
    @end_at       = options[:end_at]
    
    if @start_at.is_a?(String) and @day and @day.is_a?(String)
      # convert day to time object, build start_at using chronic
      @start_at = Chronic.parse(@start_at, :now => Time.parse(@day))
    end

    if @end_at.is_a?(String) and @day and @day.is_a?(String)
      # convert day to time object, build end_at using chronic
      @end_at = Chronic.parse(@end_at, :now => Time.parse(@day))
    end
  end
    
  def to_s
    @id.to_s
  end
    
end