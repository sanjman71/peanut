module PreferencesHelper
  def time_horizon_options
    [
      ["1 week", 7],
      ["2 weeks", 14],
      ["4 weeks", 28],
      ["60 days (approx. 2 months)", 60],
      ["90 days (approx. 3 months)", 90],
      ["180 days (approx. 6 months)", 180],
      ["365 days (approx. 1 year)", 365]
    ]
  end
  
end