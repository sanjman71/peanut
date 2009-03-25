class Event < ActiveRecord::Base
  belongs_to              :eventable, :polymorphic => true
  belongs_to              :company
  belongs_to              :user
  
  validates_presence_of   :etype, :company_id, :user_id

  # Event types
  URGENT                  = 1               # urgent messages
  APPROVAL                = 2               # messages indicating that approval is required
  INFORMATIONAL           = 3               # informational messages

  named_scope             :urgent, :conditions => {:etype => URGENT}
  named_scope             :approval, :conditions => {:etype => APPROVAL}
  named_scope             :informational, :conditions => {:etype => INFORMATIONAL}
    
end
