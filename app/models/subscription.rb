class SubscriptionError < StandardError; end

class Subscription < ActiveRecord::Base
  validates_presence_of   :time_unit, :time_value, :amount, :start_payment_at
  has_many                :payments
  
  # BEGIN acts_as_state_machhine
  include AASM
  
  aasm_column           :state
  aasm_initial_state    :initialized
  aasm_state            :initialized
  aasm_state            :authorized
  aasm_state            :active       # subscription billed successfully
  aasm_state            :frozen       # payment declined in the active state
  
  aasm_event :authorized do
    transitions :to => :authorized, :from => [:initialized]
  end

  aasm_event :active do
    transitions :to => :active, :from => [:authorized, :active]
  end

  aasm_event :frozen do
    transitions :to => :frozen, :from => [:active, :frozen]
  end
  # END acts_as_state_machine
  
  # always force start payment date to the beginning of the day
  def start_payment_at=(datetime)
    write_attribute(:start_payment_at, datetime.beginning_of_day) unless datetime.blank?
  end
  
  def errors?
    !self.errors.blank?
  end
  
  # authorize the payment and create a vault id
  def authorize(credit_card, options = {})
    # create payment
    @payment = Payment.create(:description => "authorize subscription")
    payments.push(@payment)
    
    transaction do
      # authorize payment, and request a vault id
      @payment.authorize(amount, credit_card, :store => true)
    
      if @payment.authorized?
        # transition to authorized state
        authorized!

        # store the vault id
        self.vault_id = @payment.params['customer_vault_id']
        
        # set the next payment date
        self.next_payment_at = self.start_payment_at
        
        # commit changes
        self.save
      else
        # no transition, stay in initialized state
        
        # add errors
        errors.add_to_base("Credit card is invalid")
      end

      @payment
    end
  end
  
  # bill the credit card referenced by the vault id, or using the credit card specified
  def bill(credit_card = nil)
    if self.next_payment_at.to_date > Date.today
      raise SubscriptionError, "next billing date is in the future"
    end
    
    # create payment
    @payment = Payment.create(:description => "recurring billing")
    payments.push(@payment)
    
    transaction do
      # purchase using the customer vault id, or the credit card if its specified
      @payment.purchase(amount, credit_card || vault_id)
    
      if @payment.paid?
        # transition to active state
        active!

        # set the last, next payment dates
        self.last_payment_at = Time.now
        self.next_payment_at = Time.now + eval("#{time_value}.#{time_unit}")

        # commit changes
        self.save
      else
        # transition to frozen state
        frozen!
      end

      @payment
    end
  end
  
end