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
  
end