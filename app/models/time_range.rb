# Builds a time range within a given day
class TimeRange
  attr_accessor :day, :start_at, :end_at, :duration
  
  # valid day formats
  #  - 'today', 'tomorrow', '20090101'
  # valid start/end time formats
  #  - '0300', '1 pm' 
  #  - '1200', '1230', '12xx' is handled as a special case
  def initialize(options={})
    @day          = options[:day]
    @start_at     = options[:start_at]
    @end_at       = options[:end_at]
    
    if @start_at.is_a?(String) and @day and @day.is_a?(String)
      # check for special case
      add_12_hours  = true if @start_at.match(/\d{4}/) and @start_at.match(/^12/)
      # convert day to time object, build start_at using chronic
      @start_at     = Chronic.parse(@start_at, :now => Time.parse(@day))
      # add 12 hours iff special case
      @start_at    += 12.hours if add_12_hours
    end

    if @start_at.blank? and @day
      # default to beginning of 'day'
      @start_at = Time.parse(@day).beginning_of_day
    end
    
    if @end_at.is_a?(String) and @day and @day.is_a?(String)
      # check for special case
      add_12_hours  = true if @end_at.match(/\d{4}/) and @end_at.match(/^12/)
      # convert day to time object, build end_at using chronic
      @end_at       = Chronic.parse(@end_at, :now => Time.parse(@day))
      # add 12 hours iff special case
      @end_at      += 12.hours if add_12_hours
    end

    if @end_at.blank? and @day
      # default to end of 'day'
      @end_at = Time.parse(@day).beginning_of_day + 1.day
    end
    
    # initialize duration (in minutes)
    @duration = (@end_at.to_i - @start_at.to_i) / 60
  end
    
  def to_s
    @day
  end
  
end