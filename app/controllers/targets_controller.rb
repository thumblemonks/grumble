class TargetsController < ApplicationController
  before_filter :load_target
  rescue_from ActiveRecord::RecordNotFound, :with => :target_not_found
  rescue_from ActiveRecord::RecordInvalid, :with => :target_invalid
  
  def show
    render_json({:target => {:grumble_count     => @target.grumbles.count.to_i,
                             :new_grumble_url   => new_grumble_url(:target_id => @target),
                             :grumble_index_url => grumbles_url(:target_id => @target)}},
                 :callback => 'getTarget')
  end

private

  def target_not_found
    render :nothing => true, :status => :not_found
  end

end
