# Extend ruby Range class with overlap? method
class Range
  def overlap?(range)
    self.include?(range.first) || range.include?(self.first)
  end
end