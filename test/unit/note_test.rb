require 'test/test_helper'
require 'test/factories'

class NoteTest < ActiveSupport::TestCase

  context "create note on subject" do
    setup do
      @subject = Factory(:user)
      assert_equal [], @subject.notes
      @subject.notes.create(:comment => "note 1")
      @subject.reload
    end
    
    should "have 1 note" do
      assert_equal 1, @subject.notes.size
      assert_equal ["note 1"], @subject.notes.collect(&:comment)
    end
    
    context "add note on subject using note create and push" do
      setup do
        @note2 = Note.create(:comment => "note 2")
        assert @note2.valid?
        @note2.subjects.push(@subject)
        @subject.reload
      end
      
      should "have valid subject" do
        assert_equal [@subject], @note2.subjects
      end
      
      should "have 2 notes" do
        assert_equal 2, @subject.notes.size
      end
      
      context "add note using subject attributes" do
        setup do
          @note3 = Note.create(:comment => "note 3", :subject_id => @subject.id, :subject_type => @subject.class.to_s)
          assert @note3.valid?
          @subject.reload
        end
        
        should "have valid subject" do
          assert_equal [@subject], @note3.subjects
          assert_equal @note3.subject, @subject
        end

        should "have 3 notes" do
          assert_equal 3, @subject.notes.size
        end
      end
      
      context "remove note" do
        setup do
          @note2.destroy
          @subject.reload
        end
        
        should "have 1 note" do
          assert_equal 1, @subject.notes.size
        end
      end
    end
  end  
end
