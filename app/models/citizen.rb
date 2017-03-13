class Citizen < ActiveRecord::Base
  include ApplicationHelper, UnionHelper
  belongs_to :union
  before_save :save_nid_birthdid_as_english

  validates :name_in_eng, :name_in_bng, :fathers_name, :mothers_name,
            :village, :post, :word_no, presence: true
  validate :nid_or_birthid_present
  validate :nid_birthid_numeric
  after_create :save_citizen_no
  after_save :save_citizen_no

  validates_uniqueness_of :nid, :allow_blank => true, :allow_nil => true
  validates_uniqueness_of :birthid, :allow_blank => true, :allow_nil => true
  validates :nid, length: {minimum: 13}, :allow_blank => true, :allow_nil => true
  validates :birthid, length: {minimum: 17}, :allow_blank => true, :allow_nil => true

  def set_status(status)
    self.status = status
  end

  def active?
    self.status == 'active'
  end

  def pending?
    self.status == 'pending'
  end

  def save_pending_request
    set_status(:pending)
    save_requested_at
  end

  def update_pending_request_to_active
    set_status :active
    save_saved_at
  end

  def save_requested_at
    self.requested_at = Time.now
  end

  def save_saved_at
    self.saved_at = Time.now
  end

  def save_citizen_no
    return if self.pending?
    return if self.citizen_no.present?

    ctzn_no = Citizen.where(union_id: 1).maximum(:citizen_no)
    ctzn_no = 0 if ctzn_no.nil?
    ctzn_no = ctzn_no.to_i
    ctzn_no = 1000 if ctzn_no == 0
    ctzn_no = ctzn_no + 1
    self.update_attributes(:citizen_no => ctzn_no.to_s)
  end

  def requested_at_formatted
    return String.new unless requested_at.present?
    self.requested_at.strftime("%d-%m-%Y %I:%M:%S %p")
  end

  def self.GENDERS
    {'পুরুষ' => :male, 'মহিলা' => :female, 'অন্যান্য' => :others}
  end

  def self.STATUS
    [:active, :pending]
  end

  def male?
    self.gender == 'male'
  end

  def female?
    self.gender == 'female'
  end

  def others?
    self.gender == 'others'
  end

  def gender_bangla
    return String.new unless self.gender.present?
    return 'পুরুষ' if male?
    return 'মহিলা' if female?
    return 'অন্যান্য' if others?
  end

  def barcode
    barcode = ''
    barcode << self.name_in_bng if self.name_in_bng.present?
    barcode << "\n"
    if self.nid.present?
      barcode << 'NID#'<< nid << "\n"
     elsif self.birthid.present?
      barcode << 'BirthId# '<< birthid << "\n"
    end
    barcode << 'Union: ' << self.union.name_in_bng
    barcode
  end

  def citizen_no_pdf
    return bangla_number(self.citizen_no) if self.citizen_no.present?
    bangla_number '1234567'
  end

  private

  def save_nid_birthdid_as_english
    self.nid = english_number(nid) if nid.present?
    self.birthid = english_number(birthid) if birthid.present?
  end

  def nid_or_birthid_present
    errors.add(:citizen, " National Id or BirthId is required") unless nid.present? || birthid.present?
  end

  def nid_birthid_numeric
    errors.add(:citizen, " National Id/BirthId is not a number") unless nid_or_birthid_numeric?
  end

  def nid_or_birthid_numeric?
    isnumber = is_numeric(nid.to_s) if nid.present?
    isnumber = is_numeric(birthid.to_s) if birthid.present?
    isnumber
  end

end
