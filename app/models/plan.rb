class Plan < ActiveRecord::Base
  has_many :accounts, :through => :user_company_plans
  has_many :companies, :through => :user_company_plans
end
