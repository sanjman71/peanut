require 'test_helper'

class PaymentTest < ActiveSupport::TestCase
  should_validate_presence_of   :description
  should_belong_to              :subscription
  
  context "successful payment authorization" do
    setup do
      @payment        = Payment.new(:description => "authorization")
      @credit_card    = credit_card(:number => '1')
      @payment.authorize(@amount, @credit_card) 
    end
    
    should_change("Payment.count", :by => 1) { Payment.count }
    
    should "have success flag" do
      assert @payment.success?
    end
    
    should "leave payment in authorized state" do
      assert @payment.authorized?
    end
    
    should "have a reference id" do
      assert @payment.reference
    end
  end

  context "successful payment authorization requesting a vault id" do
    setup do
      @payment        = Payment.new(:description => "authorization")
      @credit_card    = credit_card(:number => '1')
      @authorization  = @payment.authorize(@amount, @credit_card, :store => true) 
    end

    should_change("Payment.count", :by => 1) { Payment.count }
    
    should "have success flag" do
      assert @payment.success?
    end
    
    should "leave payment in authorized state" do
      assert @payment.authorized?
    end

    should "have a reference id" do
      assert @payment.reference
    end
  end
    
  context "failed payment authorization" do
    setup do
      @payment        = Payment.new(:description => "authorization")
      @credit_card    = credit_card(:number => '2')
      @payment.authorize(@amount, @credit_card)
    end
    
    should_change("Payment.count", :by => 1) { Payment.count }
    
    should "have failed flag" do
      assert !@payment.success?
    end
    
    should "have no payment reference id" do
      assert !@payment.reference
    end
    
    should "leave payment in declined state" do
      assert @payment.declined?
    end
  end

  context "exception payment authorization" do
    setup do
      @payment        = Payment.new(:description => "authorization")
      @credit_card    = credit_card(:number => '3')
      @payment.authorize(@amount, @credit_card) 
    end
    
    should_change("Payment.count", :by => 1) { Payment.count }
    
    should "have failed authorization" do
      assert !@payment.success?
    end
    
    should "have no payment reference id" do
      assert !@payment.reference
    end
    
    should "leave payment in declined state" do
      assert @payment.declined?
    end
  end
  
  context "successful payment purchase" do
    setup do
      @payment        = Payment.new(:description => "purchase")
      @credit_card    = credit_card(:number => '1')
      @payment.purchase(@amount, @credit_card) 
    end
    
    should_change("Payment.count", :by => 1) { Payment.count }
    
    should "have success flag" do
      assert @payment.success?
    end
    
    should "leave payment in paid state" do
      assert @payment.paid?
    end
    
    should "have no reference id" do
      assert !@payment.reference
    end
  end
  
end