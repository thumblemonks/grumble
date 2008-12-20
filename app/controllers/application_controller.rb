# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base

  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

private

  def load_target
    raise(ActiveRecord::RecordNotFound) unless target_id = params[:target_id] 
    @target = Target.find_or_initialize_by_uri(params[:target_id])
    @target.new_record? ? @target.save! : true
  end
  
  def record_invalid(exception)
    record = exception.record
    render_json({:errors => record.errors.to_a}, :status => :not_acceptable)
  end
  
  def render_json(obj, opts = {})
    json = obj.to_json
    json = "var grumbleData = (#{json});\n\nGrumble.#{opts[:callback]}(grumbleData)\n" if opts[:callback] && callback_requested?
    response.content_type = 'application/json'
    render :text => json, :status => opts[:status] || :ok
  end
  
  def callback_requested?
    params[:callback] == 'true'
  end
  
end
