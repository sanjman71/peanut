class Resource < ActiveRecord::Base
  belongs_to                :company
  validates_presence_of     :company_id, :name
  validates_uniqueness_of   :name, :scopy => :company_id
  
  named_scope :company,     lambda { |id| { :conditions => {:company_id => id} }}
  
  # the special anyone resource
  def self.anyone
    r = Resource.new do |o|
      o.name = "Anyone"
      o.id   = 0
    end
  end
  
end
