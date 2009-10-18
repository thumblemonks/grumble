ActionController::Routing::Routes.draw do |map|
  map.new_target '/targets',            :controller => 'targets', :action => 'new'
  map.target     '/targets/:target_id', :controller => 'targets', :action => 'show'
  
  map.new_grumble '/targets/:target_id/grumbles/new', :controller => 'grumbles', :action => 'new'
  map.grumbles    '/targets/:target_id/grumbles',     :controller => 'grumbles', :action => 'index',
                                                      :conditions => { :method => :get}
  map.grumbles    '/targets/:target_id/grumbles',     :controller => 'grumbles', :action => 'create',
                                                      :conditions => { :method => :post }
  map.grumble     '/targets/:target_id/grumbles/:id', :controller => 'grumbles', :action => 'show'
  
  map.grumbler    '/grumblers/:id',                   :controller => 'grumblers', :action => 'show'
end
