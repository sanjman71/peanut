module WaitlistCleanup
  
  # remove past waitlist objects
  def self.remove_past
    removed = 0
    Waitlist.past.each do |waitlist|
      # all waitlist time ranges must be in the past
      next if waitlist.waitlist_time_ranges.any? { |time_range| time_range.end_date >= Time.now }
      waitlist.destroy
      removed += 1
    end
    
    removed
  end
  
end