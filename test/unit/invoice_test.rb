require 'test_helper'

class InvoiceTest < ActiveSupport::TestCase
  
  should_validate_presence_of   :invoiceable_id
  should_validate_presence_of   :invoiceable_type
  should_have_many              :invoice_line_items
  
  def setup
    @owner        = Factory(:user, :name => "Owner")
    @monthly_plan = Factory(:monthly_plan)
    @subscription = Subscription.new(:user => @owner, :plan => @monthly_plan)
  end
  
  context "create appointment and invoice" do
    setup do
      @company  = Factory(:company, :subscription => @subscription)
      @johnny   = Factory(:user, :name => "Johnny")
      @company.user_providers.push(@johnny)
      @haircut  = Factory(:work_service, :name => "Haircut", :price_in_cents => 500, :company => @company)
      @user     = Factory(:user)

      # create appointment at 2 pm
      @appt     = Appointment.create(:company => @company,
                                     :service => @haircut,
                                     :provider => @johnny,
                                     :customer => @user,
                                     :start_at_string => "today 2 pm",
                                     :duration => @haircut.duration,
                                     :force => true)

      assert_valid @appt

      # create invoice
      @invoice  = Invoice.create(:invoiceable => @appt)
      assert_valid @invoice
      
      # add line item
      @li_collection = @invoice.invoice_line_items.push(InvoiceLineItem.new(:chargeable => @haircut, :price_in_cents => @haircut.price_in_cents))
      @li1 = @li_collection.first
    end
  
    should "have 1 invoice line item" do
      assert_equal 1, @invoice.invoice_line_items.size
      assert_equal @haircut, @invoice.invoice_line_items.first.chargeable
    end

    should "have invoice total equal to service price" do
      assert_equal 500, @invoice.total
      assert_equal 500, @invoice.total_as_money.cents
    end
    
    context "add product to invoice" do
      setup do
        @shampoo = Factory(:product, :name => "Shampoo", :company => @company)
        @li2     = InvoiceLineItem.new(:chargeable => @shampoo, :price_in_cents => 375)
        @invoice.invoice_line_items.push(@li2)
        @invoice.reload
      end
      
      should "have 2 invoice line items" do
        assert_equal @shampoo, @li2.chargeable
        assert_equal [@li1, @li2], @invoice.invoice_line_items
      end

      should "have an updated invoice total" do
        assert_equal 875, @invoice.total
        assert_equal 875, @invoice.total_as_money.cents
      end
      
      context "remove product from invoice" do
        setup do
          @invoice.invoice_line_items.delete(@li2)
          @invoice.reload
        end
        
        should "have 1 invoice line item" do
          assert_equal [@li1], @invoice.invoice_line_items
        end
        
        should "have an updated invoice total" do
          assert_equal 500, @invoice.total
          assert_equal 500, @invoice.total_as_money.cents
        end
      end
    end
  end  
end
