ActionController::Routing::Routes.draw do |map|

  #     targets GET    /targets(.:format)          {:controller=>"targets", :action=>"index"}
  #             POST   /targets(.:format)          {:controller=>"targets", :action=>"create"}
  #  new_target GET    /targets/new(.:format)      {:controller=>"targets", :action=>"new"}
  # edit_target GET    /targets/:id/edit(.:format) {:controller=>"targets", :action=>"edit"}
  #      target GET    /targets/:id(.:format)      {:controller=>"targets", :action=>"show"}
  #             PUT    /targets/:id(.:format)      {:controller=>"targets", :action=>"update"}
  #             DELETE /targets/:id(.:format)      {:controller=>"targets", :action=>"destroy"}
  map.new_target '/targets',            :controller => 'targets', :action => 'new'
  map.target     '/targets/:target_id', :controller => 'targets', :action => 'show'
  
  map.new_grumble '/targets/:target_id/grumbles/new', :controller => 'grumbles', :action => 'new'
  map.grumbles    '/targets/:target_id/grumbles',     :controller => 'grumbles', :action => 'index'
  map.grumble     '/targets/:target_id/grumbles/:id', :controller => 'grumbles', :action => 'show'
  
  map.grumbler    '/grumblers/:id',                   :controller => 'grumblers', :action => 'show'
  
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
