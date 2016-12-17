class TradeOrganization < ActiveRecord::Base
  include ApplicationHelper

  belongs_to :union
  has_many :trade_licenses, dependent: :destroy
  accepts_nested_attributes_for :trade_licenses,:allow_destroy => true

  validates :enterprize_name_in_eng,:enterprize_name_in_bng,
            :owners_name_eng,:owners_name_bng,
            :fathers_name,:mothers_name,
            :village_name,:post_name,
            :upazilla_name,:zilla_name,
            :business_place,:business_category,
            presence: true

  def address
      self.village_name << ',' << self.upazilla_name << ',' << self.zilla_name
  end

  def latest_trade_license
    trade_license ||= self.trade_licenses.order('fiscal_year desc').first
  end

  def fee
    if !latest_trade_license.nil?
      taka = bangla_number latest_trade_license.license_fee.to_s
      taka << ' টাকা মাত্র ।'
    end
  end

  def license_deadline
    if !latest_trade_license.nil?
      latest_trade_license.fiscal_year
    end
  end

  def license_no
    if !latest_trade_license.nil?
      latest_trade_license.licsense_no
    end
  end

  def deadline
    if !latest_trade_license.nil?
      latest_trade_license.deadline
    end
  end


  def fiscal_year
    if !latest_trade_license.nil?
      latest_trade_license.fiscal_year_show
    end
  end


end
