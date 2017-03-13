class CitizensController < InheritedResources::Base
  require 'barby'
  require 'barby/barcode'
  require 'barby/barcode/qr_code'
  require 'barby/outputter/png_outputter'

  include ApplicationHelper,UnionHelper
  before_filter :authenticate_user!
  load_and_authorize_resource

  def index
    respond_to do |format|
      format.html
      format.json { render json: CitizensDatatable.new(view_context,current_user) }
    end
  end

  def requests
    @citizens = current_user.citizens.where(status: :pending).order('requested_at asc') if user_signed_in?

    respond_to do |format|
      format.html
      format.json { render json: @citizens }
    end
  end

  def edit_request
    @citizen =  Citizen.find(params[:id]);
  end

  #PUT
  def permit_request
    @citizen =  Citizen.find(params[:id]);
    #@citizen.update_pending_request_to_active

    respond_to do |format|
      if  @citizen.update(citizen_params)
        format.html { redirect_to requests_citizens_path, notice: 'Citizen was successfully updated' }
        format.json { render :show, status: :ok, location: @citizen }
      else
        format.html { render :edit_request }
        format.json { render json: @citizen.errors, status: :unprocessable_entity }
      end
    end

  end

  # DELETE /recipes/1
  # DELETE /recipes/1.json
  def destroy
    @citizen = Citizen.find(params[:id])
    @citizen.update_attributes(status: :deleted)
    respond_to do |format|
      format.html { redirect_to citizens_url, notice: 'Citizen was successfully deleted' }
      format.json { head :no_content }
    end
  end


  def show
    @citizen = Citizen.find(params[:id])
    @barcode = barcode_output( @citizen)
    respond_to do |format|
      format.html
      format.pdf do
        #TODO:update issue date
        render :pdf => file_name,
               :template => 'citizens/show.pdf.erb',
               :layout => 'pdf.html.erb',
               :disposition => 'attachment',
               page_size: 'A4',
               :show_as_html => params[:debug].present?,
               margin:  {   top:               8,                     # default 10 (mm)
                            bottom:            0,
                            left:              5,
                            right:             5 },
               dpi:                            '300'
      end
    end
  end

  def search

  end

  def barcode_output( citizen )
    barcode_string = citizen.barcode
    barcode = Barby::QrCode.new(barcode_string, level: :q, size: 9)

    # PNG OUTPUT
    base64_output = Base64.encode64(barcode.to_png({ xdim: 4 }))
    "data:image/png;base64,#{base64_output}"
  end


  private

  def citizen_params
    params.require(:citizen).permit(:name_in_eng, :name_in_bng, :fathers_name,
                                    :mothers_name, :village, :post, :word_no, :union_id,
                                    :spouse_name,:nid,:birthid,:email,:mobile_no,:status,:gender)
  end

  def file_name
    pdf_file_name 'citizen_certificate_' << @citizen.union_code
  end
end

