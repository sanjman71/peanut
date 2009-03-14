ActionController::Routing::Routes.draw do |map|

  # user, session routes
  map.login     '/login',         :controller => 'sessions', :action => 'new', :conditions => {:method => :get}
  map.login     '/login',         :controller => 'sessions', :action => 'create', :conditions => {:method => :post}
  map.logout    '/logout',        :controller => 'sessions', :action => 'destroy'
  map.register  '/register',      :controller => 'users', :action => 'create'

  # user activation
  map.activate  '/activate/:activation_code', :controller => 'users', :action => 'activate', :activation_code => nil 

  # company signup route
  map.signup        '/signup',       :controller => 'signup', :action => 'index'
  map.signup_plan   '/signup/:plan_id', :controller => 'signup', :action => 'new'

  # invitation signup route
  map.invite    '/invite/:invitation_token', :controller => 'users', :action => 'new', :conditions => { :subdomain => /.+/ }
  
  map.resources :users, :member => { :suspend => :put, :unsuspend => :put, :purge => :delete }
  map.resources :invitations, :only => [:new, :create]
  map.resource  :session

  # special invoice routes
  map.connect   'invoices/when/:when', :controller => 'invoices', :action => 'index'
  map.connect   'invoices/range/:start_date..:end_date', :controller => 'invoices', :action => 'index'

  # unauthorized route
  map.unauthorized  '/unauthorized', :controller => 'home', :action => 'unauthorized'
  
  map.resources :companies, :only => [:index, :show, :edit, :update, :destroy]
  map.resources :appointments, 
                :member => { :confirmation => :get, :checkout => [:get, :put], :cancel => [:get, :post] },
                :collection => { :search => [:get, :post] }
  map.resources :openings, :collection => { :search => [:get, :post] }, :only => [:index]
  map.resources :notes, :only => [:create]
  map.resources :service_providers, :only => [:create, :destroy]
  map.resources :invoices, :member => {:add => :post, :remove => :post}, :collection => {:search => :post}, :only => [:index, :show, :add, :remove]
  map.resources :invoice_line_items
  map.resources :waitlist, :only => [:index]
  
  # openings search/index path, scoped by service and (optional) schedulable
  map.connect   ':schedulable_type/:schedulable_id/services/:service_id/openings/:when/:time', 
                 :controller => 'openings', :action => 'index'
  map.connect   'services/:service_id/openings/:when/:time', 
                 :controller => 'openings', :action => 'index'

  # search openings for a specified service and duration, and an optional schedulable
  map.connect   ':schedulable_type/:schedulable_id/services/:service_id/:duration/openings/:start_date..:end_date/:time', 
                :controller => 'openings', :action => 'index', :conditions => {:start_date => /\d{8,8}/, :end_date => /\d{8,8}/}
  map.connect   ':schedulable_type/:schedulable_id/services/:service_id/:duration/openings/:when/:time',
                 :controller => 'openings', :action => 'index'
  map.connect   'services/:service_id/:duration/openings/:start_date..:end_date/:time', 
                 :controller => 'openings', :action => 'index', :conditions => {:start_date => /\d{8,8}/, :end_date => /\d{8,8}/}
  map.connect   'services/:service_id/:duration/openings/:when/:time', 
                 :controller => 'openings', :action => 'index'

  # show/edit calendars scoped by schedulable (and optional format)
  map.connect   ':schedulable_type/:schedulable_id/calendar/when/:when', :controller => 'calendar', :action => 'show'
  map.connect   ':schedulable_type/:schedulable_id/calendar/when/:when.:format', :controller => 'calendar', :action => 'show'
  map.connect   ':schedulable_type/:schedulable_id/calendar/range/:start_date..:end_date', :controller => 'calendar', :action => 'show'
  map.connect   ':schedulable_type/:schedulable_id/calendar/range/:start_date..:end_date.:format', :controller => 'calendar', :action => 'show'
  map.connect   ':schedulable_type/:schedulable_id/calendar', :controller => 'calendar', :action => 'show'
  map.connect   ':schedulable_type/:schedulable_id/calendar.:format', :controller => 'calendar', :action => 'show'
  map.connect   ':schedulable_type/:schedulable_id/calendar/edit', :controller => 'calendar', :action => 'edit'
  
  # search calendars scoped by schedulable
  map.connect   ':schedulable_type/:schedulable_id/calendar/search', :controller => 'calendar', :action => 'search'

  # schedule a work appointment with a schedulable for a specified service and duration
  map.schedule  'book/work/:schedulable_type/:schedulable_id/services/:service_id/:duration/:start_at', 
                :controller => 'appointments', :action => 'new', :mark_as => 'work', :conditions => {:method => :get}
  map.schedule  'book/work/:schedulable_type/:schedulable_id/services/:service_id/:duration/:start_at', 
                :controller => 'appointments', :action => 'create', :mark_as => 'work', :conditions => {:method => :post}

  # schedule a waitlist appointment with a schedulable for a specific service and date range
  map.waitlist  'book/wait/:schedulable_type/:schedulable_id/services/:service_id/:start_date..:end_date',
                :controller => 'appointments', :action => 'new', :mark_as => 'wait', 
                :conditions => {:method => :get, :start_date => /\d{8,8}/, :end_date => /\d{8,8}/}
  map.waitlist  'book/wait/:schedulable_type/:schedulable_id/services/:service_id/:start_date..:end_date',
                :controller => 'appointments', :action => 'create', :mark_as => 'wait', 
                :conditions => {:method => :post, :start_date => /\d{8,8}/, :end_date => /\d{8,8}/}
    
  # toggle a schedulable's calendar
  map.connect   ':schedulable_type/:schedulable_id/calendar/toggle',
                :controller => 'company_schedulables', :action => 'toggle', :conditions => {:method => :post}
   
  # services, products
  map.resources :services
  map.resources :products
  
  # customers with nested resources
  map.resources :customers,         :has_many => [:appointments]

  # This allows us to get access to locations without going through their owner, if required.
  # It at least gives us some useful automatic route definitions like edit_location_url etc.
  map.resources :locations,         :member => {:select => :get}

  # Plans and subscriptions
  map.resources :plans
  map.connect   'subscriptions/errors', :controller => 'subscriptions', :action => 'index', :filter => 'errors'
  map.resources :subscriptions, :member => { :edit_cc => :get, :update_cc => :post }
  map.change_subscription   '/change_subscription', :controller => 'subscriptions', :action => 'edit'
  map.update_subscription   '/update_subscription/:plan_id', :controller => 'subscriptions', :action => 'update'

  # Administrative controllers
  map.badges 'badges/:action/:id', :controller => 'badges'

  # map the root to the home controller
  map.root                  :controller => 'home', :action => 'index', :conditions => { :subdomain => "www" }
  
  # map the company root to the companies controller
  map.show_company_root  '/show', :controller => 'companies', :action => 'show', :conditions => { :subdomain => /.+/ }
  map.edit_company_root  '/edit', :controller => 'companies', :action => 'edit', :conditions => { :subdomain => /.+/ }

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
