ActionController::Routing::Routes.draw do |map|

  # user, session routes
  map.login     '/login',         :controller => 'sessions', :action => 'new', :conditions => {:method => :get}
  map.login     '/login',         :controller => 'sessions', :action => 'create', :conditions => {:method => :post}
  map.logout    '/logout',        :controller => 'sessions', :action => 'destroy'

  # ping
  map.ping      '/ping',          :controller => 'openings', :action => 'ping'

  # rpx routes
  map.rpx_login '/rpx/login', :controller => 'rpx', :action => 'login'
  map.rpx_add   '/rpx/add/:id',   :controller => 'rpx', :action => 'add'

  # password routes
  map.password_forgot '/password/forgot', :controller => 'passwords', :action => 'forgot'
  map.password_reset  '/password/reset', :controller => 'passwords', :action => 'reset', :conditions => {:method => :post}
  map.password_clear  '/users/:id/password/clear', :controller => 'passwords', :action => 'clear', :conditions => {:method => :put}
  
  # user activation
  map.activate      '/activate/:activation_code', :controller => 'users', :action => 'activate', :activation_code => nil 

  # company signup route
  map.signup        '/signup',          :controller => 'signup', :action => 'index'
  map.signup_beta   '/signup/beta',     :controller => 'signup', :action => 'beta'
  map.signup_check  '/signup/check',    :controller => 'signup', :action => 'check', :conditions => {:method => :post}
  map.signup_plan   '/signup/:plan_id', :controller => 'signup', :action => 'new', :conditions => {:method => :get}
  map.signup_create '/signup/:plan_id', :controller => 'signup', :action => 'create', :conditions => {:method => :post}

  # invitation signup route
  map.invite              '/invite/:invitation_token', :controller => 'users', :action => 'new', :conditions => { :subdomain => /.+/ }
  
  map.resources         :users, :member => { :suspend => :put, :unsuspend => :put, :purge => :delete, :exists => :post, :add_rpx => :get}
  map.user_notify       '/users/:id/notify/:type', :controller => 'users', :action => 'notify', :conditions => {:method => :get}
  map.user_edit         '/users/:id/edit', :controller => 'users', :action => 'edit'
  map.user_delete       '/users/:id', :controller => 'users', :action => 'destroy', :conditions => {:method => :delete}
  map.user_sudo         '/users/:id/sudo', :controller => 'users', :action => 'sudo'
  map.user_grant_role   '/users/:id/grant/:role', :controller => 'users', :action => 'grant', :conditions => {:method => :put}
  map.user_revoke_role  '/users/:id/revoke/:role', :controller => 'users', :action => 'revoke', :conditions => {:method => :put}

  map.user_email_promote  '/users/:user_id/email/:id/promote', :controller => 'email_addresses', :action => 'promote'
  map.user_email_delete   '/users/:user_id/email/:id', :controller => 'email_addresses', :action => 'destroy', :conditions => {:method => :delete}

  map.user_phone_promote  '/users/:user_id/phone/:id/promote', :controller => 'phone_numbers', :action => 'promote'
  map.user_phone_delete   '/users/:user_id/phone/:id', :controller => 'phone_numbers', :action => 'destroy', :conditions => {:method => :delete}

  map.staff_new    '/staffs/new',       :controller => 'users', :action => 'new', :role => 'company staff', :conditions => {:method => :get}
  map.staff_create '/staffs/create',    :controller => 'users', :action => 'create', :role => 'company staff', :conditions => {:method => :post}
  map.staff_edit   '/staffs/:id/edit',  :controller => 'users', :action => 'edit', :role => 'company staff', :conditions => {:method => :get}
  map.staff_update '/staffs/:id',       :controller => 'users', :action => 'update', :role => 'company staff', :conditions => {:method => :put}

  map.customer_new    '/customers/new',       :controller => 'users', :action => 'new', :role => 'company customer', :conditions => {:method => :get}
  map.customer_create '/customers/create',    :controller => 'users', :action => 'create', :role => 'company customer', :conditions => {:method => :post}
  map.customer_create_format '/customers/create.:format', :controller => 'users', :action => 'create', :role => 'company customer', :conditions => {:method => :post}
  map.customer_edit   '/customers/:id/edit',  :controller => 'users', :action => 'edit', :role => 'company customer', :conditions => {:method => :get}
  map.customer_update '/customers/:id',       :controller => 'users', :action => 'update', :role => 'company customer', :conditions => {:method => :put}
  map.customer_delete '/customers/:id',       :controller => 'users', :action => 'destroy', :role => 'company customer', :conditions => {:method => :delete}

  # user appointment routes
  map.user_appts_done     '/users/:user_id/appointments/cleanup/done',
                          :controller => 'appointments', :action => 'cleanup', :type => 'work', :done => 1, :conditions => {:method => :get}
  map.user_appts_cleanup  '/users/:user_id/appointments/cleanup', 
                          :controller => 'appointments', :action => 'cleanup', :type => 'work', :conditions => {:method => :get}
  map.user_appts_state    '/users/:user_id/appointments/:state',
                          :controller => 'appointments', :action => 'index', :type => 'work', :state => /confirmed|upcoming|completed|canceled|noshow/,
                          :conditions => {:method => :get}
  map.user_appts          '/users/:user_id/appointments', :controller => 'appointments', :action => 'index', :type => 'work',
                          :conditions => {:method => :get}

  # appointment routes
  map.company_appts_state '/appointments/:state', 
                          :controller => 'appointments', :action => 'index', :type => 'work', :state => /confirmed|upcoming|completed|canceled|noshow/,
                          :conditions => {:method => :get}
  map.company_appts       '/appointments', :controller => 'appointments', :action => 'index', :type => 'work',
                          :conditions => {:method => :get}
  map.resources           :appointments,
                          :member => {:approve => [:get, :put], :noshow => [:get, :put], :complete => [:get, :put], :cancel => [:get, :put, :post],
                                      :reschedule => :put, :move => :put}

  # staff and customer specialized routes; otherwise use more generic user routes
  map.resources           :staffs, :only => [:index]
  map.resources           :customers, :only => [:index]

  # special invoice routes
  map.connect   'invoices/when/:when', :controller => 'invoices', :action => 'index'
  map.connect   'invoices/range/:start_date..:end_date', :controller => 'invoices', :action => 'index'

  # unauthorized route
  map.unauthorized  '/unauthorized', :controller => 'home', :action => 'unauthorized'

  map.resources :companies, :only => [:index, :show, :edit, :update, :destroy], :member => {:setup => :get, :freeze => :put, :unfreeze => :put}
  map.resources :openings, :collection => { :search => [:get, :post] }, :only => [:index]
  map.resources :resources, :only => [:new, :create, :edit, :update]
  map.resources :notes, :only => [:create]
  map.resources :service_providers, :only => [:create, :destroy]
  map.resources :invoices, :member => {:add => :post, :remove => :post}, :collection => {:search => :post}, :only => [:index, :show, :add, :remove]
  map.resources :invoice_line_items
  map.resources :waitlists, :only => [:index, :create]

  # Deprecasted: history routes
  # map.resources :history, :only => [:index], :collection => {:waitlist => :get}
  
  # search openings for a specified service and duration, and an optional provider
  map.openings_provider_dates '/:provider_type/:provider_id/services/:service_id/:duration/openings/:start_date..:end_date/:time',
                              :controller => 'openings', :action => 'index', :start_date => /\d{8,8}/, :end_date => /\d{8,8}/
  map.openings_provider_date  '/:provider_type/:provider_id/services/:service_id/:duration/openings/:start_date/:time',
                              :controller => 'openings', :action => 'index', :start_date => /\d{8,8}/
  map.openings_provider_when  '/:provider_type/:provider_id/services/:service_id/:duration/openings/:when/:time',
                              :controller => 'openings', :action => 'index'
  map.openings_anyone_dates   '/services/:service_id/:duration/openings/:start_date..:end_date/:time',
                              :controller => 'openings', :action => 'index', :start_date => /\d{8,8}/, :end_date => /\d{8,8}/
  map.openings_anyone_date    '/services/:service_id/:duration/openings/:start_date/:time',
                              :controller => 'openings', :action => 'index', :start_date => /\d{8,8}/
  map.openings_anyone_when    '/services/:service_id/:duration/openings/:when/:time',
                              :controller => 'openings', :action => 'index'

  # schedule a work appointment with a provider for a specified service and duration
  # map.schedule_service_start_duration '/schedule/:provider_type/:provider_id/services/:service_id/:duration/:start_at',
  #                                     :controller => 'appointments', :action => 'new', :mark_as => 'work', :conditions => {:method => :get}
  # map.schedule_service_start          '/schedule/:provider_type/:provider_id/services/:service_id/:start_at',
  #                                     :controller => 'appointments', :action => 'new', :mark_as => 'work', :conditions => {:method => :get}
  map.schedule      '/schedule/:provider_type/:provider_id/services/:service_id/:duration/:start_at',
                    :controller => 'appointments', :action => 'create_work', :mark_as => 'work', :conditions => {:method => :post}
  map.schedule_work '/schedule/work',
                    :controller => 'appointments', :action => 'create_work', :mark_as => 'work', :conditions => {:method => :post}

  # schedule a waitlist appointment with a provider for a specific service
  map.waitlist  '/waitlist/:provider_type/:provider_id/services/:service_id',
                :controller => 'waitlists', :action => 'new', :conditions => {:method => :get}

  map.show_appt_waitlist  '/waitlists/appointments/:appointment_id', :controller => 'appointment_waitlists', :action => 'show'

  # schedule a waitlist appointment with a provider for a specific service and date range
  # map.waitlist  'book/wait/:provider_type/:provider_id/services/:service_id/:start_date..:end_date',
  #               :controller => 'appointments', :action => 'new', :mark_as => 'wait', 
  #               :conditions => {:method => :get, :start_date => /\d{8,8}/, :end_date => /\d{8,8}/}
  # map.waitlist  'book/wait/:provider_type/:provider_id/services/:service_id/:start_date..:end_date',
  #               :controller => 'appointments', :action => 'create_wait', :mark_as => 'wait', 
  #               :conditions => {:method => :post, :start_date => /\d{8,8}/, :end_date => /\d{8,8}/}

  # edit, update and create provider free time, single appointment, block appointments, or weekly recurring appointments
  map.create_free   '/:provider_type/:provider_id/calendar/free',
                    :controller => 'appointments', :action => 'create_free', :conditions => {:method => :post}
  map.update_free   '/:provider_type/:provider_id/calendar/:id/free',
                    :controller => 'appointments', :action => 'update_free', :conditions => {:method => :post}

  map.new_block     '/:provider_type/:provider_id/calendar/block/new', :controller => 'appointments', :action => 'new_block'
  map.create_block  '/:provider_type/:provider_id/calendar/block',
                    :controller => 'appointments', :action => 'create_block', :conditions => {:method => :post}

  map.new_weekly    '/:provider_type/:provider_id/calendar/weekly/new', :controller => 'appointments', :action => 'new_weekly'
  map.show_weekly   '/:provider_type/:provider_id/calendar/weekly', :controller => 'appointments', :action => 'show_weekly',
                     :conditions => {:method => :get}
  map.edit_weekly   '/:provider_type/:provider_id/calendar/weekly/:id/edit', :controller => 'appointments', :action => 'edit_weekly'
  map.create_weekly '/:provider_type/:provider_id/calendar/weekly',
                    :controller => 'appointments', :action => 'create_weekly', :conditions => {:method => :post}
  map.update_weekly '/:provider_type/:provider_id/calendar/:id/weekly',
                    :controller => 'appointments', :action => 'update_weekly', :conditions => {:method => :put}

  # test fullcalendar
  map.connect       '/:provider_type/:provider_ids/calendar2', :controller => 'calendar', :action => 'show2',
                    :provider_ids => /(\d+(,\d+)*)|(all)/

  # show/edit calendars scoped by provider (and optional format)
  map.calendar_when_start   '/:provider_type/:provider_id/calendar/when/:when/:start_date',
                            :controller => 'calendar', :action => 'show', :start_date => /[0-9]{8}/
  map.calendar_when         '/:provider_type/:provider_id/calendar/when/:when', :controller => 'calendar', :action => 'show'
  map.calendar_when_format  '/:provider_type/:provider_id/calendar/when/:when.:format', :controller => 'calendar', :action => 'show'
  map.calendar_date_range         '/:provider_type/:provider_id/calendar/range/:start_date..:end_date', :controller => 'calendar', :action => 'show'
  map.calendar_date_range_format  '/:provider_type/:provider_id/calendar/range/:start_date..:end_date.:format', :controller => 'calendar', :action => 'show'
  map.calendar_show         '/:provider_type/:provider_id/calendar', :controller => 'calendar', :action => 'show'
  map.calendar_show_format  '/:provider_type/:provider_id/calendar.:format', :controller => 'calendar', :action => 'show'
  map.range_type_show '/:provider_type/:provider_id/calendar/:range_type/:start_date', 
                       :controller => 'calendar', :action => 'show', :range_type => /daily|weekly|monthly|none/, :start_date => /[0-9]{8}/
  map.connect         '/:provider_type/:provider_id/calendar/:range_type/:start_date.:format', 
                       :controller => 'calendar', :action => 'show', :range_type => /daily|weekly|monthly|none/, :start_date => /[0-9]{8}/

  # search calendars scoped by provider
  map.calendar_search ':provider_type/:provider_id/calendar/search', :controller => 'calendar', :action => 'search'

  # list calendars
  map.calendars       '/calendars', :controller => 'calendar', :action => 'index'

  # search waitlist scoped by provider
  map.connect         '/:provider_type/:provider_id/waitlist/:state', :controller => 'waitlists', :action => 'index'
  map.connect         '/:provider_type/:provider_id/waitlist', :controller => 'waitlists', :action => 'index'

  # services, products
  map.resources :services
  map.resources :products

  # vacations
  map.company_vacations         '/vacations', :controller => 'vacations', :action => 'index'
  map.provider_vacations        '/:provider_type/:provider_id/vacations', :controller => 'vacations', :action => 'index', :provider_id => /\d+/
  map.create_company_vacation   '/vacation', :controller => 'vacations', :action => 'create', :conditions => {:method => :post}
  map.create_provider_vacation  '/:provider_type/:provider_id/vacation',
                                :controller => 'vacations', :action => 'create', :conditions => {:method => :post}
  map.delete_provider_vacation  '/:provider_type/:provider_id/vacation/:id',
                                :controller => 'vacations', :action => 'destroy', :conditions => {:method => :delete}
  map.delete_company_vacation   '/vacation/:id', :controller => 'vacations', :action => 'destroy', :conditions => {:method => :delete}

  # capacity slots
  map.provider_capacity         '/:provider_type/:provider_id/capacity/start/:start_time/duration/:duration', 
                                :controller => 'capacity_slots', :action => 'capacity'

  # reports
  map.resources         :reports, :only => [:index], :collection => {:route => :post}
  map.report_providers  '/reports/range/:start_date..:end_date/:state/providers/:provider_ids',
                        :controller => 'reports', :action => 'show', :state => /all|confirmed|canceled|completed|noshow/, :provider_ids => /\d+(,\d+)*/
  map.report_services   '/reports/range/:start_date..:end_date/:state/services/:service_ids',
                        :controller => 'reports', :action => 'show', :state => /all|confirmed|canceled|completed|noshow/, :service_ids => /\d+(,\d+)*/
  map.report_range      '/reports/range/:start_date..:end_date/:state', 
                        :controller => 'reports', :action => 'show', :state => /all|confirmed|canceled|completed|noshow/
  
  # This allows us to get access to locations without going through their owner, if required.
  # It at least gives us some useful automatic route definitions like edit_location_url etc.
  map.resources :locations,     :member => {:select => :get}

  # Subscriptions
  map.resources :subscriptions, :member => { :edit_cc => :get, :update_cc => :post }
  map.update_subscription '/subscriptions/:id/plan/:plan_id', :controller => 'subscriptions', :action => 'update', :conditions => {:method => :get}

  map.resources :promotions, :only => [:new, :create, :index]
  map.resources :invitations, :only => [:new, :create], :member => {:resend => :get}
  map.resource  :session, :only => [:new, :create, :destroy]

  # Messages controller
  map.resources :messages, :only => [:index, :create], :member => {:info => [:get, :post]}

  # Tasks controller
  map.task_appt_messages  '/tasks/appointments/messages/:time_span', 
                          :controller => 'tasks', :action => 'appointment_messages', :time_span => /whenever/
  map.task_appt_reminders '/tasks/appointments/reminders/:time_span', 
                          :controller => 'tasks', :action => 'appointment_reminders', :time_span => /\d+-(days|hours)/
  map.task_user_messages  '/tasks/users/messages/:time_span', 
                          :controller => 'tasks', :action => 'user_messages', :time_span => /whenever/
  map.task_expand_recur   '/tasks/expand_all_recurrences',
                          :controller => 'tasks', :action => 'expand_all_recurrences'
  map.task_schedule_messages  '/tasks/schedules/messages/:time_span',
                              :controller => 'tasks', :action => 'schedule_messages', :time_span => /daily/
  map.task_rebuild_demos  '/tasks/rebuild_demos',
                          :controller => 'tasks', :action => 'rebuild_demos'
  map.resources           :tasks, :only => [:index]

  # Administrative controllers
  map.badges 'badges/:action/:id', :controller => 'badges'

  map.resources :log_entries, :member => {:mark_as_seen => :post}, :only => [:index, :create, :destroy]
  map.connect   '/log_entries/:state', :controller => 'log_entries', :action => 'index', :state => /seen|unseen/

  # map the root to the home controller, and let the home controller figure out the subdomain
  map.root      :controller => 'home', :action => 'index'
  map.faq       '/faq', :controller => 'home', :action => 'faq'
  map.demos     '/demos', :controller => 'home', :action => 'demos'
  map.tryit     '/tryit', :controller => 'home', :action => 'tryit'

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
