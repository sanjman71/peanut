class CompanyService < ActiveRecord::Base
  belongs_to                :company, :counter_cache => :services_count
  belongs_to                :service
end
