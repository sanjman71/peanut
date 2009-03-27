class CreateEvents < ActiveRecord::Migration
  def self.up
    create_table :events do |t|
      t.references  :eventable, :polymorphic => true    # e.g. appointment
      t.references  :company, :null => false            # company this is relevant to
      t.references  :location                           # company location this is relevant to, if any
      t.references  :customer                           # customer this is relevant to, if any
      t.references  :user                               # user who created the event
      t.string      :message                            # event message
      t.integer     :etype                              # informational, approval, urgent
      t.boolean     :seen                               # event marked as seen
      t.timestamps
    end
  end

  def self.down
    drop_table :events
  end
end
