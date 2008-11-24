require 'test/test_helper'
require 'test/factories'

class NoteTest < ActiveSupport::TestCase

  def test_create_and_delete
    customer  = Factory(:customer)

    # create note using a subject class
    assert_equal [], customer.notes
    customer.notes.create(:comment => "note 1")
    customer.reload
    assert_equal 1, customer.notes.size
    assert_equal ["note 1"], customer.notes.collect(&:comment)
    
    # create a note using the note class
    note = Note.create(:comment => "note 2")
    note.subjects.push(customer)
    customer.reload
    assert note.valid?
    assert_equal [customer], note.subjects
    
    # create a note using subject attributes
    note = Note.create(:comment => "note 3", :subject_id => customer.id, :subject_type => customer.class.to_s)
    assert note.valid?
    customer.reload
    assert_equal [customer], note.subjects
    assert_equal note.subject, customer
  end
  
end
