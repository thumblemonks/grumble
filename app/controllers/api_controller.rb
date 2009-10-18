class ApiController < ApplicationController
  skip_before_filter :verify_authenticity_token
private

  def load_target
    raise(ActiveRecord::RecordNotFound) unless target_id = params[:target_id] 
    @target = Target.for_uri(params[:target_id])
    @target.new_record? ? @target.save! : true
  end

  def record_invalid(exception)
    record = exception.record
    render_json({:errors => record.errors.to_a}, :status => :not_acceptable)
  end

  def render_json(obj, opts = {})
    json = obj.to_json
    if opts[:callback] && callback_requested?
      json = json_with_callback(json, opts)
    end
    response.content_type = 'application/json'
    render :text => json, :status => opts[:status] || :ok
  end

  def callback_requested?
    !params[:callback].blank?
  end

  def json_with_callback(json, opts)
    "var grumbleData = (#{json});\n\ndocument.getElementById(#{params[:callback].to_json}).#{opts[:callback]}(grumbleData);\n" 
  end
  
end