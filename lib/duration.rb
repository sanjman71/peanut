class Duration
  
  # return duration as a string description
  # options:
  #  - :prepend => prepend duration with specified value
  def self.to_words(duration_in_minutes, options={})
    return '' if duration_in_minutes.blank? or duration_in_minutes == 0

    # force duration to integer
    duration_in_minutes = duration_in_minutes.to_i
  
    if duration_in_minutes >= 60
      # use hours
      hours, mins = [duration_in_minutes / 60, duration_in_minutes % 60]
      phrase = mins > 0 ? "#{pluralize(hours, 'hour')}, #{pluralize(mins, 'minute')}" : "#{pluralize(hours, 'hour')}"
    else
      # use minutes
      phrase = "#{duration_in_minutes} minutes"
    end
    
    options[:prepend] ? "#{options[:prepend]} #{phrase}" : phrase
  end

  def self.pluralize(count, singular)
    "#{count || 0} " + ((count == 1 || count == '1') ? singular : singular.pluralize)
  end
end