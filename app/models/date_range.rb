class DateRange
  attr_accessor :when, :start_at, :end_at, :days
  
  def self.today
    Time.now.beginning_of_day.utc
  end
  
  def initialize(s)
    raise ArgumentError if s.blank?

    if !Appointment::WHENS_EXTENDED.include?(s.to_s)
      raise ArgumentError, "unsupported when #{s}"
    end
    
    if s == 'later'
      # special case, range should be 2 weeks after next week, adjusted by a day
      range       = Chronic.parse('next week', :guess => false)
      @when       = s
      @start_at   = range.last + 1.day
      @end_at     = range.last + 1.day + 2.weeks
    elsif s == 'next 2 weeks'
      # use [today, today + 2 weeks]
      @when       = s
      @start_at   = Time.now.beginning_of_day
      @end_at     = @start_at + 2.weeks
    else
      # parse when string
      range = Chronic.parse(s, :guess => false)
      
      if range.blank?
        @when = :error
        return
      end

      # initialize when
      @when       = s
      
      # always set start_at to beginning of day
      @start_at   = range.first.beginning_of_day
      @end_at     = range.last

      if s == 'this week'
        # make 'this week' end on monday 12am
        @end_at += 1.day
      elsif s == 'next week'
        # make 'next week' go from monday to monday
        @start_at += 1.day
        @end_at   += 1.day
      end
    end

    # store start, end times in utc
    @start_at = @start_at.utc
    @end_at   = @end_at.utc
    
    # compute days
    @days     = (@end_at - @start_at).to_i / (60 * 60 * 24)
  end
  
end