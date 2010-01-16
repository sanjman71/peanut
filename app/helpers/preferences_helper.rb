module PreferencesHelper
  def time_horizon_options
    [
      ["1 week", 7.days.to_s],
      ["2 weeks", 14.days.to_s],
      ["4 weeks", 28.days.to_s],
      ["2 months", 2.months.to_s],
      ["3 months", 3.months.to_s],
      ["6 months", 6.months.to_s],
      ["1 year", 1.year.to_s]
    ]
  end

  def start_wday_options
    [
      ["Sunday", "0"],
      ["Monday", "1"]
    ]
  end

  def appt_start_minutes_options
    [
      ["On the hour only", "[0]"],
      ["Every 30 minutes", "[0,30]"]
    ]
  end

  def appt_confirmation_options
    [
      ["Yes", "1"],
      ["No", "0"]
    ]
  end

  def public_options
    [
      ["Public", "1"],
      ["Private", "0"]
    ]
  end

end