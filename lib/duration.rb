class Duration
  
  # return duration as a string description
  # options:
  #  - :prepend => prepend duration with specified value
  def self.to_words(duration_in_seconds, options={})
    return '' if duration_in_seconds.blank? or duration_in_seconds == 0

    # force duration to integer
    duration_in_seconds = duration_in_seconds.to_i

    days = (duration_in_seconds / 1.day).to_i
    duration_in_seconds -= days.days
    hours = (duration_in_seconds / 1.hour).to_i
    duration_in_seconds -= hours.hours
    minutes = (duration_in_seconds / 1.minute).to_i
    duration_in_seconds -= minutes.minutes
    phrase = options[:prepend].blank? ? [] : [options[:prepend]]
    phrase << "#{pluralize(days, 'day')}" unless (days == 0)
    phrase << "#{pluralize(hours, 'hour')}" unless (hours == 0)
    phrase << "#{pluralize(minutes, 'minute')}" unless (minutes == 0)
    phrase << "#{pluralize(duration_in_seconds, 'second')}" unless (duration_in_seconds == 0)
    phrase.to_sentence

  end

  def self.pluralize(count, singular)
    "#{count || 0} " + ((count == 1 || count == '1') ? singular : singular.pluralize)
  end
end