module PreferencesHelper
  def time_horizon_options
    [
      ["1 week", 7.days],
      ["2 weeks", 14.days],
      ["4 weeks", 28.days],
      ["2 months", 2.months],
      ["3 months", 3.months],
      ["6 months", 6.months],
      ["1 year", 1.year]
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
end