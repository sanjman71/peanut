class JavascriptsController < ApplicationController

  # map services to resources able to provide them
  def skillset
    @skills = Service.work.inject([]) do |array, service|
      service.people.each do |person|
        array << [service.id, person.id, person.name]
      end
      array
    end
    
    render :text => @skills.to_json
  end
  
end
