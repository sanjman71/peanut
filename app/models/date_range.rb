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
    
    @start_at     = options[:start_at] if options[:start_at]
    @end_at       = options[:end_at] if options[:end_at]
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
  # options:
  #   - start_on => day of week to start calendar on, 0-6 where 0 is sunday, defaults to start_at
  def self.parse_when(s, options={})
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
    elsif s == 'next 4 weeks'
      # use [today, today + 4 weeks]
      start_at  = Time.now.beginning_of_day
      end_at    = start_at + 4.weeks
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

    # adjust calendar based on start_on day
    start_at = adjust_start_day_to_start_on(start_at, options)
      
    DateRange.new(Hash[:when => s.titleize, :start_at => start_at, :end_at => end_at])
  end
  
  # parse start, end dates - e.g. "20090101", defaults to end date inclusive
  # options:
  #   - exclusive => true|false, if true do not include end date in range, default is inclusive or exclusive == false  #   - start_on => [0..6], day of week to start calendar on, 0 is sunday
  #   - start_on => day of week to start calendar on, 0-6 where 0 is sunday, defaults to start_at
  def self.parse_range(start_date, end_date, options={})
    # parse options
    exclusive   = options[:exclusive] == true
    
    # build name from start, end dates
    range_name  = "#{Time.parse(start_date).to_s(:appt_short_month_day_year)} - #{Time.parse(end_date).to_s(:appt_short_month_day_year)}"
    start_at    = Time.parse(start_date)
    
    if exclusive
      end_at = Time.parse(end_date)
    else
      end_at = Time.parse(end_date) + 1.day
    end

    # adjust calendar based on start_on day
    start_at = adjust_start_day_to_start_on(start_at, options)

    DateRange.new(Hash[:when => range_name, :start_at => start_at, :end_at => end_at])
  end
  
  def each
    Range.new(0, @days-1).each do |i|
      yield @start_at + i.days
    end
  end
  
  protected
  
  # adjust start_at based on start_on day
  def self.adjust_start_day_to_start_on(start_at, options)
    start_on = options[:start_on] || start_at.wday
    
    if start_on != start_at.wday
      # need to show x days before start_at to start on the correct day
      subtract_days = start_at.wday > start_on ? start_at.wday - start_on : 7 - (start_on - start_at.wday)
      start_at      -= subtract_days.days
    end
    
    start_at
  end
end