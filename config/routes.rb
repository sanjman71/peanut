ActionController::Routing::Routes.draw do |map|

  # user, session routes
  map.signup    '/signup',        :controller => 'users', :action => 'new' 
  map.login     '/login',         :controller => 'sessions', :action => 'new'
  map.logout    '/logout',        :controller => 'sessions', :action => 'destroy'
  map.register  '/register',      :controller => 'users', :action => 'create'

  # user activation
  map.activate '/activate/:activation_code', :controller => 'users', :action => 'activate', :activation_code => nil 

  map.resources :users, :member => { :suspend => :put, :unsuspend => :put, :purge => :delete }
  map.resource  :session

  map.resources :companies
  map.resources :appointments, :member => { :confirmation => :get, :checkout => :put, :cancel => :get }, :collection => { :search => :any }
  map.resources :openings, :collection => { :search => :any }
  map.resources :notes

  # override 'appointments/new' path
  map.schedule        'schedule/people/:person_id/services/:service_id/:start_at', :controller => 'appointments', :action => 'new'
    
  map.resources :people do |resource|
    # nested appointments routes
    resource.resources :appointments
    # nested openings routes
    resource.resources :openings
    
    # nested services routes
    resource.resources :services,   :has_many => [:appointments, :openings]
  end
  
  # services with nested resources
  map.resources :services,          :has_many => [:appointments, :openings]
  
  # customers with nested resources
  map.resources :customers,         :has_many => [:appointments]

  # javascript routes
  map.resources :javascripts,       :collection => {:service_providers => :get}
    
  # map the company root to the companies controller
  map.company_root  '',     :controller => 'companies', :action => 'index', :conditions => { :subdomain => /.+/ }

  # map the root to the companies controller
  map.root                  :controller => 'companies', :action => 'index'
  
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
