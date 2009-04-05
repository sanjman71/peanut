class Event < ActiveRecord::Base
  belongs_to              :eventable, :polymorphic => true
  belongs_to              :company
  belongs_to              :user
  belongs_to              :customer, :class_name => 'User'
  
  validates_presence_of   :etype, :company_id, :user_id

  # Event types
  URGENT                  = 1               # urgent messages
  APPROVAL                = 2               # messages indicating that approval is required
  INFORMATIONAL           = 3               # informational messages

  named_scope             :urgent, :conditions => {:etype => URGENT}
  named_scope             :approval, :conditions => {:etype => APPROVAL}
  named_scope             :informational, :conditions => {:etype => INFORMATIONAL}
  named_scope             :seen, :conditions => {:seen => true}
  named_scope             :unseen, :conditions => ['seen = ? or seen is null', false]
  
  # order by start_at, most recent first
  named_scope             :order_recent, {:order => 'updated_at DESC'}
  
  def seen?
    self.seen == true
  end
    
end
