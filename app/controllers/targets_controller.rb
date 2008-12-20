class TargetsController < ApiController
  rescue_from ActiveRecord::RecordNotFound, :with => :target_not_found
  rescue_from ActiveRecord::RecordInvalid,  :with => :record_invalid
  
  def show
    load_target
    render_json({:target => target_as_json_attributes(@target)}, :callback => 'getTarget')
  end

private

  def target_not_found
    render :nothing => true, :status => :not_found
  end

  def target_as_json_attributes(target)
    {:grumble_count     => @target.grumbles.count.to_i,
     :new_grumble_url   => new_grumble_url(:target_id => @target),
     :grumble_index_url => grumbles_url(:target_id => @target)}
  end
    
end
