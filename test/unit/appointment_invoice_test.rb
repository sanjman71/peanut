require 'test/test_helper'
require 'test/factories'

class AppointmentInvoiceTest < ActiveSupport::TestCase
  
  # shoulda
  should_require_attributes :appointment_id
  
  context "create appointment and invoice" do
    setup do
      @company  = Factory(:company)
      @johnny   = Factory(:user, :name => "Johnny", :companies => [@company])
      @haircut  = Factory(:work_service, :name => "Haircut", :company => @company, :price_in_cents => 500)
      @user     = Factory(:user)

      # create appointment at 2 pm
      @appt     = Appointment.create(:company => @company,
                                     :service => @haircut,
                                     :resource => @johnny,
                                     :owner => @user,
                                     :start_at_string => "today 2 pm")

      assert_valid @appt

      # create invoice
      @appt.invoice  = AppointmentInvoice.create
      @invoice       = @appt.invoice
      assert_valid @invoice
      
      # get first line item
      @li1          = @invoice.line_items.first
    end
  
    should "have 1 invoice line item" do
      assert_equal 1, @invoice.line_items.size
      assert_equal @haircut, @li1.chargeable
    end

    should "have invoice total equal to service price" do
      assert_equal 500, @invoice.total
      assert_equal 500, @invoice.total_as_money.cents
    end
    
    context "add product to invoice" do
      setup do
        @shampoo = Factory(:product, :name => "Shampoo", :company => @company)
        @li2     = AppointmentInvoiceLineItem.new(:chargeable => @shampoo, :price_in_cents => 375)
        @invoice.line_items.push(@li2)
        @invoice.reload
      end
      
      should "have 2 invoice line items" do
        assert_equal @shampoo, @li2.chargeable
        assert_equal [@li1, @li2], @invoice.line_items
      end

      should "have an updated invoice total" do
        assert_equal 875, @invoice.total
        assert_equal 875, @invoice.total_as_money.cents
      end
      
      context "remove product from invoice" do
        setup do
          @invoice.line_items.delete(@li2)
          @invoice.reload
        end
        
        should "have 1 invoice line item" do
          assert_equal [@li1], @invoice.line_items
        end
        
        should "have an updated invoice total" do
          assert_equal 500, @invoice.total
          assert_equal 500, @invoice.total_as_money.cents
        end
      end
    end
  end  
end
