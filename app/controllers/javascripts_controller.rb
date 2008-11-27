class JavascriptsController < ApplicationController

  # map services to resources able to provide them
  def service_providers
    @service_providers = Service.work.inject([]) do |array, service|
      service.people.each do |person|
        array << [service, person]
      end
      array
    end
  end
  
end
