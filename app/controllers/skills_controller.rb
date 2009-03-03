class SkillsController < ApplicationController
  
  # POST /skills/create
  def create
    @skill = Skill.create(params[:skill])
    
    if !@skill.valid?
      logger.debug("*** errors: #{@skill.errors.full_messages}")
    end
    
    render_component(:controller => 'services',  :action => 'providers', :id => @skill.service.id,
                     :layout => false, :params => {:authenticity_token => params[:authenticity_token] })
  end
  
  # DELETE /skills/1
  def destroy
    @skill = Skill.find(params[:id])
    @skill.destroy
    
    render_component(:controller => 'services',  :action => 'providers', :id => @skill.service.id,
                     :layout => false, :params => {:authenticity_token => params[:authenticity_token] })
  end

end