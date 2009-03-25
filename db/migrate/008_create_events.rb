class CreateEvents < ActiveRecord::Migration
  def self.up
    create_table :events do |t|
      t.references  :eventable, :polymorphic => true    # e.g. users
      t.integer     :company_id                         # company this is relevant to
      t.integer     :location_id                        # company location this is relevant to, if any
      t.integer     :user_id                            # user who created the event
      t.string      :message                            # event message
      t.integer     :etype                              # informational, approval, urgent
      t.string      :approve_url                        # if approval type, the URL to approve
      t.string      :reject_url                         # if approval type, the URL to reject
      t.references  :action_user                        # if action is taken, which user
      t.datetime    :action_dt                          # if action is taken, when
      t.string      :action_message                     # if action is taken, any notes
      t.timestamps
    end
  end

  def self.down
    drop_table :events
  end
end
