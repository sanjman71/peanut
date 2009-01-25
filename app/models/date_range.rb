class DateRange
  attr_accessor :name, :start_at, :end_at, :days
  cattr_accessor :errors
  
  # extend ActiveRecord so we can use the Errors module
  extend ActiveRecord

  # include enumerable mixin which requires an 'each' method
  include Enumerable
  
  def initialize(options={})
    @name         = options[:when]
    
    if @name == 'error'
      # create error object
      @error  = true
      @errors = ActiveRecord::Errors.new(self)
      @errors.add_to_base("When is invalid")
      return
    end
    
    @start_at     = options[:start_at].utc if options[:start_at]
    @end_at       = options[:end_at].utc if options[:end_at]
    @days         = (@end_at - @start_at).to_i / (60 * 60 * 24)
    
    # initialize enumerable param
    @index        = 0
  end
  
  def valid?
    !@error
  end

  def errors
    @errors ||= ActiveRecord::Errors.new(self)
  end
  
  def self.today
    Time.today.utc
  end
  
  # parse when string into a valid date range
  def self.parse_when(s)
    if !(Appointment::WHENS_EXTENDED + Appointment::WHENS_PAST).include?(s)
      return DateRange.new(Hash[:when => 'error'])
    end
    
    if s == 'today'
      start_at  = Time.now.beginning_of_day
      end_at    = start_at + 1.day
    elsif s == 'tomorrow'
      start_at  = Time.now.tomorrow.beginning_of_day
      end_at    = start_at + 1.day
    elsif s == 'this week'
      # this week ends on sunday night midnight
      end_at    = Time.now.end_of_week + 1.second
      start_at  = Time.now.beginning_of_day
    elsif s == 'next week'
      # next week starts on monday
      start_at  = Time.now.next_week
      end_at    = start_at + 1.week
    elsif s == 'next 2 weeks'
      # use [today, today + 2 weeks]
      start_at  = Time.now.beginning_of_day
      end_at    = start_at + 2.weeks
    elsif s == 'later'
      # should start after 'next week', and last for 2 weeks
      start_at  = Time.now.next_week + 1.week
      end_at    = start_at + 2.weeks
    elsif s == 'past week'
      end_at    = Time.now.end_of_day + 1.second
      start_at  = end_at - 1.week
    elsif s == 'past 2 weeks'
      end_at    = Time.now.end_of_day + 1.second
      start_at  = end_at - 2.weeks
    elsif s == 'past month'
      end_at    = Time.now.end_of_day + 1.second
      start_at  = end_at - 1.month
    end
      
    DateRange.new(Hash[:when => s.titleize, :start_at => start_at, :end_at => end_at])
  end
  
  # parse start, end dates - e.g. "20090101", defaults to end date inclusive
  def self.parse_range(start_date, end_date, options={})
    # parse options
    exclusive   = options[:exclusive] == true
    
    # build name from start, end dates
    range_name  = "#{Time.parse(start_date).to_s(:appt_short_month_day_year)} - #{Time.parse(end_date).to_s(:appt_short_month_day_year)}"
    
    if exclusive
      DateRange.new(Hash[:when => range_name, :start_at => Time.parse(start_date), :end_at => Time.parse(end_date)])
    else
      DateRange.new(Hash[:when => range_name, :start_at => Time.parse(start_date), :end_at => Time.parse(end_date) + 1.day])
    end
  end
  
  def each
    Range.new(0, @days-1).each do |i|
      yield @start_at + i.days
    end
  end
  
end