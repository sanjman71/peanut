class DateRange
  attr_accessor :name, :start_at, :end_at, :days
  cattr_accessor :errors
  
  # extend ActiveRecord so we can use the Errors module
  extend ActiveRecord

  # include enumerable mixin which requires an 'each' method
  include Enumerable
  
  def initialize(options={})
    @name = options[:name]
    
    if @name == 'error'
      # create error object
      @error  = true
      @errors = ActiveRecord::Errors.new(self)
      @errors.add_to_base("When is invalid")
      return
    end
    
    @start_at     = options[:start_at] if options[:start_at]
    @end_at       = options[:end_at] if options[:end_at]
    
    if @start_at and @end_at
      # if end_at ends at 59 minutes and 59 seconds, add 1 second to make sure the days calculation is correct
      seconds   = (@end_at - @start_at).to_i
      seconds   += 1 if @end_at.min == 59 and @end_at.sec == 59
      # convert seconds to days
      @days     = seconds / (60 * 60 * 24)
    else
      @days     = 0
    end
    
    # initialize enumerable param
    @index = 0
  end
  
  def valid?
    !@error
  end

  def errors
    @errors ||= ActiveRecord::Errors.new(self)
  end
  
  def each
    # range is inclusive
    Range.new(0, @days-1).each do |i|
      yield @start_at + i.days
    end
  end
  
  def self.today
    Time.today.utc
  end
  
  # parse when string into a valid date range
  # options:
  #  - start_on  => [0..6], day of week to start calendar on, 0 is sunday, defaults to start_at
  #  - end_on    => [0..6], day of week to end calendar on, 0 is sunday, defaults to end_at
  #  - include   => :today, add today if utc day <> local time day 
  def self.parse_when(s, options={})
    # initialize now to utc time
    now = Time.now.utc
    
    if (m = s.match(/next (\d{1}) week/)) # e.g. 'next 3 weeks', 'next 1 week'
      # use [today, today + n weeks]
      n         = m[1].to_i
      start_at  = now.beginning_of_day
      end_at    = start_at + n.weeks
    else
      case s
      when 'today'
        start_at  = now.beginning_of_day
        end_at    = start_at + 1.day
      when 'tomorrow'
        start_at  = now.tomorrow.beginning_of_day
        end_at    = start_at + 1.day
      when 'this week'
        # this week ends on sunday night at midnight
        end_at    = now.end_of_week + 1.second
        start_at  = now.beginning_of_day
        if options[:include] == :today
          start_at -= 1.day if now.yday > Time.now.yday
        end
      when 'next week'
        # next week starts on monday
        start_at  = now.next_week
        end_at    = start_at + 1.week
      when 'later'
        # should start after 'next week', and continue for 2 weeks
        start_at  = now.next_week + 1.week
        end_at    = start_at + 2.weeks
      when 'past week'
        end_at    = now.end_of_day + 1.second
        start_at  = end_at - 1.week
      when 'past 2 weeks'
        end_at    = now.end_of_day + 1.second
        start_at  = end_at - 2.weeks
      when 'past month'
        end_at    = now.end_of_day + 1.second
        start_at  = end_at - 1.month
      else
        return DateRange.new(Hash[:name => 'error'])
      end
    end
    
    # adjust calendar based on start_on and end_on days
    start_at  = adjust_start_day_to_start_on(start_at, options)
    end_at    = adjust_end_day_to_end_on(end_at, options)
      
    DateRange.new(Hash[:name => s.titleize, :start_at => start_at, :end_at => end_at])
  end
  
  # parse start, end dates - e.g. "20090101", defaults to end date inclusive
  # options:
  #   - inclusive => true|false, if true not include end date in range, default is true
  #   - start_on  => [0..6], day of week to start calendar on, 0 is sunday, defaults to start_at.wday
  #   - end_on    => [0..6], day of week to end calendar on, 0 is sunday, defaults to end_at.wday
  def self.parse_range(start_date, end_date, options={})
    # parse options
    inclusive   = options.has_key?(:inclusive) ? options[:inclusive] : true
    
    # build name from start, end dates
    range_name  = "#{Time.parse(start_date).to_s(:appt_short_month_day_year)} - #{Time.parse(end_date).to_s(:appt_short_month_day_year)}"
    # build start_at, end_at times in utc format
    start_at    = Time.parse(start_date).utc.beginning_of_day
    end_at      = Time.parse(end_date).utc.beginning_of_day
    
    if inclusive
      # include the last day by adjusting to the end of the day
      end_at = end_at.end_of_day
    end

    # adjust calendar based on start_on, end_on day
    start_at  = adjust_start_day_to_start_on(start_at, options)
    end_at    = adjust_end_day_to_end_on(end_at, options)
    
    DateRange.new(Hash[:name => range_name, :start_at => start_at, :end_at => end_at])
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
  
  # adjust end_at based on end_on day
  def self.adjust_end_day_to_end_on(end_at, options)
    # if end_on was specified, adjust it 1 day because we really want the beginning of the next day
    end_on = options[:end_on] ? options[:end_on] : end_at.wday
    
    if end_on != end_at.wday
      # add x days if the end on day is greater than the current day of the week
      add_days    = end_on > end_at.wday ? end_on - end_at.wday + 1 : 7 - (end_at.wday - end_on)
      end_at     += add_days.days
    end
    
    end_at
  end
end