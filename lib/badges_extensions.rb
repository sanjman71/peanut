module BadgesExtensions

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    # add class method as a before filter
    def privilege_required_any(privilege, options = {})
      before_filter (options||{}) { |c| c.send :privilege_required_any, privilege, options }
    end
  end

  protected
  
  def current_privileges
    @current_privileges ||= Hash.new
  end

  # the privilege cache maps authorizables to a list of privilege names
  def init_current_privileges
    @current_privileges = Hash.new
    
    if logged_in?
      if current_company
        # load and cache privileges on current company
        @current_privileges[current_company] = current_user.privileges(current_company).collect(&:name)
      else
        # load and cache privileges without an authorizable object
        @current_privileges[:noauth] = current_user.privileges.collect(&:name)
      end
    else
      # no privilege cache
    end
  end

  # check user privileges against the pre-loaded memory collection instead of using the database
  def has_privilege?(p, authorizable=nil, user=nil)
    user      ||= current_user
    cache_key = authorizable.blank? ? :noauth : authorizable

    # logger.debug("*** has_privilege? #{user ? user.name : ''}:'#{p}':#{authorizable ? authorizable.name : ""}")

    if current_privileges.has_key?(cache_key)
      # logger.debug("*** checking cached privileges for authorizable: #{cache_key}")
      # check cached privileges using cache key
      privileges = current_privileges[cache_key]
      privileges.include?(p)
    else
      # use default implementation
      super
    end
  end

  # ensure privileges on at least one of the authorizables
  def privilege_required_any(privilege, options={})
    # check that :on option exists and is an array
    if !options.has_key?(:on) or !options[:on].is_a?(Array)
      # use default implementation handle the regular case
      return privilege_required(privilege, options)
    end

    # copy options hash, and use the copy from here on
    dup_options = options.dup
    
    # iterate over each 'on' option
    on_options  = dup_options.delete(:on)
    on_options.each do |on_option|
      # rebuild options with specific 'on' option
      dup_options[:on] = on_option

      # find user and authorizable
      user          = get_by_method_or_attribute(dup_options[:user])
      authorizable  = get_authorizable_object(dup_options)

      # check privilege
      result  = has_privilege?(privilege, authorizable, user)

      # puts "*** privilege_required_any: #{user ? user.name : nil}:#{privilege}:#{authorizable ? authorizable.name : nil} is #{result}"

      if result
        # call privilege_required to handle the dup_options success
        return privilege_required(privilege, dup_options)
      end
    end
    
    # they all failed, pick any option and call privilege_required to handle failure
    return privilege_required(privilege, dup_options.merge(:on => on_options.first))
  end

end