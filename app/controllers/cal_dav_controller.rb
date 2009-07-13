# Copyright (c) 2006 Stuart Eccles
# Released under the MIT License.  See the LICENSE file for more details.

# The controller must then have a route of
# map.connect 'mydav/*path_info', :controller => 'my_dav', :action => 'webdav'
#
# it is then necessary to implement some or all of the following methods mkcol_for_path(path), write_content_to_path(path, content), 
# copy_to_path(resource, dest_path, depth), move_to_path(resource, dest_path, depth), get_resource_for_path(path)
#
# get_resource_for_path needs to return a WebDAVResource object such as FileWebDavResource
#
# To add webdav authentication to your controller just use
# class MyDavController < ActionController::Base
#   act_as_railsdav
#   before_filter :my_auth
#
#   def my_auth()
#       basic_auth_required {|username, password| session[:user] = User.your_authentication(username,password) }
#   end

class CalDavController < ApplicationController
  
  act_as_railsdav
  
  protected

  # URL format is http://<subdomain>.walnutcalendar.com/caldav([/provider/<provider_id>]|[/location/<location_id>])[/<caldav_token>]
  # We're read only, so we only support reading data from a calendar right now
  def get_resource_for_path(path)

    debugger

    # Get the different arguments in the caldav path
    args = path.split('/')
    caldav_token = provider_id = location_id = nil
    while args.size > 0
      if args.size == 1
        caldav_token = args[0]
        args = []
      elsif (args[0] == "provider")
        provider_id = args[1] || nil
        args = args[2...args.length]
      elsif (args[0] == "location")
        location_id = args[1] || nil
        args = args[2...args.length]
      end
    end
    
    if (caldav_token.nil?)
      # Public URL. Calendar of public events
      # Raise an exception for now
      raise WebDavErrors::ForbiddenError
    else
      # Private URLs - user id specified
      # Check that the user_id works and the token matches the user
      # @caldav_user = caldav_token.nil? ? nil : User.find_by_caldav_token(caldav_token)
      @caldav_user = caldav_token.nil? ? nil : User.find_by_email(caldav_token)

      if @caldav_user.nil?
        # The token is invalid      
        raise WebDavErrors::ForbiddenError
      end
      
      @provider = provider_id.nil? ? nil : User.find_by_id(provider_id)
      if (@provider && !@caldav_user.has_privilege?('read calendar', @provider))
        raise WebDavErrors::ForbiddenError
      end

      @location = location_id.nil? ? nil : Location.find_by_id(location_id)
      if (@location && !@caldav_user.has_privilege?('read calendar', @location))
        raise WebDavErrors::ForbiddenError
      end
      
      if (@location.nil? && @provider.nil? && !@caldav_user.has_privilege?('read calendar', current_company))
        raise WebDavErrors::ForbiddenError
      end

    end

    # initialize daterange
    @daterange    = DateRange.parse_when('next 4 weeks')    

    # find free, work appointments for the specified provider over a daterange
    @appointments = AppointmentScheduler.find_free_work_appointments(current_company, @location, @provider, @daterange)

    if @appointments
      return CalDavResource.new(@appointments, current_company)
    else
      raise WebDavErrors::NotFoundError
    end
  end

end

