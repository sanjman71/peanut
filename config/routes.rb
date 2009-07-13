ActionController::Routing::Routes.draw do |map|

  # user, session routes
  map.login     '/login',         :controller => 'sessions', :action => 'new', :conditions => {:method => :get}
  map.login     '/login',         :controller => 'sessions', :action => 'create', :conditions => {:method => :post}
  map.logout    '/logout',        :controller => 'sessions', :action => 'destroy'

  # rpx routes
  map.rpx_customer  '/rpx/customer',  :controller => 'rpx', :action => 'customer'
  # map.rpx_provider  '/rpx/provider',  :controller => 'rpx', :action => 'provider'

  # user activation
  map.activate  '/activate/:activation_code', :controller => 'users', :action => 'activate', :activation_code => nil 

  # company signup route
  map.signup        '/signup',          :controller => 'signup', :action => 'index'
  map.signup_plan   '/signup/:plan_id', :controller => 'signup', :action => 'new'

  # invitation signup route
  map.invite    '/invite/:invitation_token', :controller => 'users', :action => 'new', :conditions => { :subdomain => /.+/ }
  
  map.resources :users, :member => { :suspend => :put, :unsuspend => :put, :purge => :delete }
  map.connect   '/users/:id/notify/:type', :controller => 'users', :action => 'notify', :conditions => {:method => :get}
  map.connect   '/providers/new',       :controller => 'users', :action => 'new', :role => 'provider', :conditions => {:method => :get}
  map.connect   '/providers/create',    :controller => 'users', :action => 'create', :role => 'provider', :conditions => {:method => :post}
  map.connect   '/providers/:id/edit',  :controller => 'users', :action => 'edit', :role => 'provider', :conditions => {:method => :get}
  map.connect   '/providers/:id',       :controller => 'users', :action => 'update', :role => 'provider', :conditions => {:method => :put}
  map.connect   '/customers/new',       :controller => 'users', :action => 'new', :role => 'customer', :conditions => {:method => :get}
  map.connect   '/customers/create',    :controller => 'users', :action => 'create', :role => 'customer', :conditions => {:method => :post}
  map.connect   '/customers/:id/edit',  :controller => 'users', :action => 'edit', :role => 'customer', :conditions => {:method => :get}
  map.connect   '/customers/:id',       :controller => 'users', :action => 'update', :role => 'customer', :conditions => {:method => :put}
  map.connect   '/customers/:customer_id/appointments/:state', :controller => 'appointments', :action => 'index', :type => 'work',
                :conditions => {:method => :get, :state => /upcoming|completed|canceled/}
  map.connect   '/customers/:customer_id/appointments', :controller => 'appointments', :action => 'index', :type => 'work',
                :conditions => {:method => :get}

  # appointment routes
  map.connect   '/appointments/:state', :controller => 'appointments', :action => 'index', :type => 'work', :state => /upcoming|completed|canceled/,
                :conditions => {:method => :get}
  map.connect   '/appointments', :controller => 'appointments', :action => 'index', :type => 'work',
                :conditions => {:method => :get}
  map.resources :appointments,
                :member => {:cancel => :get, :complete => :post, :reschedule => [:get, :post]},
                :collection => { :search => [:get, :post] }
                                        
  map.resources :providers, :member => { :toggle_manager => :post }
  map.resources :customers, :only => [:index, :show], :shallow => true, :has_many => [:appointments]
  
  map.resources :invitations, :only => [:new, :create]
  map.resource  :session

  # special invoice routes
  map.connect   'invoices/when/:when', :controller => 'invoices', :action => 'index'
  map.connect   'invoices/range/:start_date..:end_date', :controller => 'invoices', :action => 'index'

  # unauthorized route
  map.unauthorized  '/unauthorized', :controller => 'home', :action => 'unauthorized'
  
  map.resources :companies, :only => [:index, :show, :edit, :update, :destroy], :member => {:setup => :get}
  map.resources :openings, :collection => { :search => [:get, :post] }, :only => [:index]
  map.connect   '/openings/reschedule', :controller => 'openings', :action => 'index', :type => 'reschedule', :conditions => {:method => :get}
  map.resources :resources, :only => [:new, :create, :edit, :update]
  map.resources :notes, :only => [:create]
  map.resources :service_providers, :only => [:create, :destroy]
  map.resources :invoices, :member => {:add => :post, :remove => :post}, :collection => {:search => :post}, :only => [:index, :show, :add, :remove]
  map.resources :invoice_line_items
  map.resources :waitlist, :only => [:index]
  
  # search openings for a specified service and duration, and an optional provider
  map.connect   ':provider_type/:provider_id/services/:service_id/:duration/openings/:start_date..:end_date/:time', 
                :controller => 'openings', :action => 'index', :conditions => {:start_date => /\d{8,8}/, :end_date => /\d{8,8}/}
  map.connect   ':provider_type/:provider_id/services/:service_id/:duration/openings/:when/:time',
                 :controller => 'openings', :action => 'index'
  map.connect   'services/:service_id/:duration/openings/:start_date..:end_date/:time', 
                 :controller => 'openings', :action => 'index', :conditions => {:start_date => /\d{8,8}/, :end_date => /\d{8,8}/}
  map.connect   'services/:service_id/:duration/openings/:when/:time', 
                 :controller => 'openings', :action => 'index'

  # show/edit calendars scoped by provider (and optional format)
  map.connect   ':provider_type/:provider_id/calendar/when/:when', :controller => 'calendar', :action => 'show'
  map.connect   ':provider_type/:provider_id/calendar/when/:when.:format', :controller => 'calendar', :action => 'show'
  map.connect   ':provider_type/:provider_id/calendar/range/:start_date..:end_date', :controller => 'calendar', :action => 'show'
  map.connect   ':provider_type/:provider_id/calendar/range/:start_date..:end_date.:format', :controller => 'calendar', :action => 'show'
  map.connect   ':provider_type/:provider_id/calendar', :controller => 'calendar', :action => 'show'
  map.connect   ':provider_type/:provider_id/calendar.:format', :controller => 'calendar', :action => 'show'
  map.connect   ':provider_type/:provider_id/calendar/edit', :controller => 'calendar', :action => 'edit'
  
  # search calendars scoped by provider
  map.connect   ':provider_type/:provider_id/calendar/search', :controller => 'calendar', :action => 'search'

  # search waitlist scoped by provider
  map.connect   ':provider_type/:provider_id/waitlist/:state', :controller => 'waitlist', :action => 'index'
  map.connect   ':provider_type/:provider_id/waitlist', :controller => 'waitlist', :action => 'index'

  # schedule a work appointment with a provider for a specified service and duration
  map.schedule  'book/work/:provider_type/:provider_id/services/:service_id/:duration/:start_at', 
                :controller => 'appointments', :action => 'new', :mark_as => 'work', :conditions => {:method => :get}
  map.schedule  'book/work/:provider_type/:provider_id/services/:service_id/:duration/:start_at', 
                :controller => 'appointments', :action => 'create', :mark_as => 'work', :conditions => {:method => :post}

  # schedule a waitlist appointment with a provider for a specific service and date range
  map.waitlist  'book/wait/:provider_type/:provider_id/services/:service_id/:start_date..:end_date',
                :controller => 'appointments', :action => 'new', :mark_as => 'wait', 
                :conditions => {:method => :get, :start_date => /\d{8,8}/, :end_date => /\d{8,8}/}
  map.waitlist  'book/wait/:provider_type/:provider_id/services/:service_id/:start_date..:end_date',
                :controller => 'appointments', :action => 'create', :mark_as => 'wait', 
                :conditions => {:method => :post, :start_date => /\d{8,8}/, :end_date => /\d{8,8}/}
    
  # toggle a provider's calendar
  map.connect   ':provider_type/:provider_id/calendar/toggle',
                :controller => 'company_providers', :action => 'toggle', :conditions => {:method => :post}
   
  # services, products
  map.resources :services
  map.resources :products
  
  # This allows us to get access to locations without going through their owner, if required.
  # It at least gives us some useful automatic route definitions like edit_location_url etc.
  map.resources :locations,         :member => {:select => :get}

  # Subscriptions
  map.resources :subscriptions, :member => { :edit_cc => :get, :update_cc => :post }
  map.update_subscription '/subscriptions/:id/plan/:plan_id', :controller => 'subscriptions', :action => 'update', :conditions => {:method => :get}

  # Messages controller
  map.connect   '/messages/deliver/:type', :controller => 'messages', :action => 'deliver', :conditions => {:method => :post}
  
  # Administrative controllers
  map.badges 'badges/:action/:id', :controller => 'badges'
  
  map.resources :log_entries, :member => {:mark_as_seen => :post}, :only => [:index, :create, :destroy]
  map.connect   '/log_entries/:state', :controller => 'log_entries', :action => 'index', :state => /seen|unseen/

  # map the root to the home controller, and let the home controller figure out the subdomain
  map.root :controller => 'home', :action => 'index'
  
  # map the company root edit action to the companies controller
  map.edit_company_root  'edit', :controller => 'companies', :action => 'edit'

  # map the company caldav
  map.connect 'caldav/*path_info', :controller => 'cal_dav', :action => 'webdav'  

  # debug controller
  map.connect   'debug/grid', :controller => 'debug', :action => 'toggle_blueprint_grid', :conditions => {:method => :put}  

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing the them or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
