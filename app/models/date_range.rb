class DateRange
  attr_accessor :name, :start_at, :end_at, :days, :errors
  
  # include enumerable mixin which requires an 'each' method
  include Enumerable
  
  def initialize(options={})
    @name         = options[:when]
    @errors       = (@name == 'error') 
    @start_at     = options[:start_at].utc if options[:start_at]
    @end_at       = options[:end_at].utc if options[:end_at]
    
    # compute days
    @days         = (@end_at - @start_at).to_i / (60 * 60 * 24)
    
    # initialize enumerable param
    @index        = 0
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
      
    DateRange.new(Hash[:when => s, :start_at => start_at, :end_at => end_at])
  end
  
  def each
    Range.new(0, @days-1).each do |i|
      yield @start_at + i.days
    end
  end
  
end