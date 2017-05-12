class CitizensController < InheritedResources::Base
  require 'barby'
  require 'barby/barcode'
  require 'barby/barcode/qr_code'
  require 'barby/outputter/png_outputter'

  include ApplicationHelper, UnionHelper
  before_filter :authenticate_user!
  load_and_authorize_resource

  def new
    @citizen = Citizen.new
    @citizen.build_contact_address
    @citizen.build_citizen_basic
    @citizen.basic_infos.build(lang: current_lang)
    @citizen.addresses.build(address_type: :present, lang: current_lang)
    @citizen.addresses.build(address_type: :permanent, lang: current_lang)
  end

  def index
    respond_to do |format|
      format.html
      format.json { render json: CitizensDatatable.new(view_context, current_user) }
    end
  end

  def requests
    @citizens = current_user.citizens.where(status: :pending)
                    .order('requested_at asc')
                    .per_page_kaminari(params[:page])
                    .per(10) if user_signed_in?
    #@users = User.order(:name).page params[:page]
    #@citizens = Citizen.per_page_kaminari(params[:page]).per(10)

    respond_to do |format|
      format.html
      format.json { render json: @citizens }
    end
  end

  def edit_request
    @citizen = Citizen.find(params[:id]);
  end

  #PUT
  def permit_request
    @citizen = Citizen.find(params[:id]);
    #@citizen.save_citizen_no

    respond_to do |format|
      if @citizen.update(citizen_params)
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
    @barcode = barcode_output(@citizen) if params[:format] == 'pdf'

    respond_to do |format|
      format.html
      format.pdf do
        render :pdf => file_name,
               :template => 'citizens/show.pdf.erb',
               :layout => 'pdf.html.erb',
               :disposition => 'attachment',
               page_size: 'A4',
               :show_as_html => params[:debug].present?,
               margin: {top: 8, # default 10 (mm)
                        bottom: 0,
                        left: 5,
                        right: 5},
               dpi: '300'
      end
    end
  end

  def search

  end

  def barcode_output(citizen)
    barcode_string = citizen.barcode
    barcode = Barby::QrCode.new(barcode_string, level: :q, size: 9)

    # PNG OUTPUT
    base64_output = Base64.encode64(barcode.to_png({xdim: 4}))
    "data:image/png;base64,#{base64_output}"
  end


  private

  def citizen_params
    params.require(:citizen).permit(:union_id, :nid, :birthid, basic_infos_attributes: [:name, :fathers_name, :mothers_name, :date_of_birth, :lang],
                                    addresses_attributes: [:village, :road, :word_no, :district, :upazila, :post_office, :address_type, :lang],
                                    contact_address_attributes: [:mobile_no, :email],
                                    citizen_basic_attributes:[:nid,:birthid,:dob,:gender,:maritial_status_id,
                                                              :citizenship_status_id,:religion_id])
  end

  def file_name
    pdf_file_name 'citizen_certificate_' << @citizen.union_code
  end
end

