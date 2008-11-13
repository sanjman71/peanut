class DateRange
  attr_accessor :when, :start_at, :end_at, :days
  
  # include enumerable mixin which requires an 'each' method
  include Enumerable
  
  def self.today
    Time.now.beginning_of_day.utc
  end
  
  def initialize(options)
    raise ArgumentError if options.blank?
    
    # parse options
    @when = options[:when]
    
    if !Appointment::WHENS_EXTENDED.include?(@when)
      raise ArgumentError, "unsupported when #{@when}"
    end
    
    if @when == 'later'
      # special case, range should be 2 weeks after next week, adjusted by a day
      range       = Chronic.parse('next week', :guess => false)
      @start_at   = range.last + 1.day
      @end_at     = range.last + 1.day + 2.weeks
    elsif @when == 'next 2 weeks'
      # use [today, today + 2 weeks]
      @start_at   = Time.now.beginning_of_day
      @end_at     = @start_at + 2.weeks
    elsif @when == 'today'
      @start_at   = Time.now.beginning_of_day
      @end_at     = @start_at + 1.day
    else
      # parse when string
      range = Chronic.parse(@when, :guess => false)
      
      if range.blank?
        @when = :error
        return
      end

      # always set start_at to beginning of day
      @start_at   = range.first.beginning_of_day
      @end_at     = range.last

      if @when == 'this week'
        # make 'this week' end on monday 12am
        @end_at += 1.day
      elsif @when == 'next week'
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
    
    # initialize enumerable params
    @index    = 0
  end
  
  def each
    Range.new(0, @days-1).each do |i|
      yield @start_at + i.days
    end
  end
  
end