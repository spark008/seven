class DeliverableValidationsController < ApplicationController
  before_filter :authenticated_as_admin

  def update_deliverable
    # find the proper params hash
    params_hash = params[:uploaded_script_validation] || params[:proc_validation] || params[:deliverable_validation]
    # identify the appropriate class (yes, reflection can probably do a better job...)
    case params_hash[:type]
    when 'UploadedScriptValidation'
      new_class = UploadedScriptValidation
    when 'ProcValidation'
      new_class = ProcValidation
    else
      flash[:error] = "Don't mess with the validation type."
      redirect_to root_path
      return
    end
    params_hash.delete :type
    
    # figure out whether we're creating or updating a record
    @deliverable = Deliverable.find(params[:id])
    @deliverable.transaction do       
      if @deliverable.deliverable_validation && @deliverable.deliverable_validation.class != new_class
        @deliverable.deliverable_validation = nil
      end
        
      @new_record = @deliverable.deliverable_validation.nil?
      @deliverable.deliverable_validation = new_class.new(params_hash) if @new_record
      @deliverable_validation = @deliverable.deliverable_validation

      # record / update data here
      @deliverable_validation.time_limit ||= 60
      @success = @new_record ? @deliverable_validation.save! : @deliverable_validation.update_attributes!(params_hash)
      @deliverable.save! if @success
    end
    
    # render the result
    respond_to do |format|
      format.js # update_deliverable.js.rjs
      if @success
        format.html do
          flash[:notice] = 'Deliverable validation was successfully updated.'
          redirect_to :controller => :assignments, :action => :index
        end
      else
        format.html do
          flash[:error] = 'Failed to update deliverable validation.'
          redirect_to :controller => :assignments, :action => :index
        end
      end
    end    
  end

  # GET /deliverable_validations/1/contents
  def contents
    @deliverable_validation = DeliverableValidation.find params[:id]
    send_data @deliverable_validation.pkg.file_contents,
              :filename => @deliverable_validation.pkg.original_filename,
              :type => @deliverable_validation.pkg_content_type
  end
end
