class GrumblesController < ApiController
  before_filter :load_target
  rescue_from ActiveRecord::RecordInvalid,  :with => :record_invalid
    
  def index
    grumbles = @target.grumbles.map { |grumble| grumble_attributes(grumble) }
    render_json({:grumbles => grumbles}, :callback => 'grumblesFetched')
  end

  def create
    grumble = @target.grumbles.build(params[:grumble].slice(:subject, :body, :anon_grumbler_name))
    grumble.save!
    render_json({:grumble => grumble_attributes(grumble)}, :callback => 'grumbleCreated', :status => :created)
  end
  
private

  def grumble_attributes(grumble)
    grumble_data = {:id => grumble.uuid, :grumble_url => grumble_url(:id => grumble, :target_id => grumble.target), 
                    :grumbler_name => grumble.grumbler_name, :subject => grumble.subject, :body => grumble.body, 
                    :created_at => grumble.created_at.to_i}
    grumble_data[:grumbler_url] = grumbler_url(grumble.grumbler) if grumble.grumbler    
    grumble_data
  end


end
