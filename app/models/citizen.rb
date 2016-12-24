class Citizen < ActiveRecord::Base
  include ApplicationHelper,UnionHelper
  belongs_to :union
  before_save :save_nid_birthdid_as_english

  validates :name_in_eng,:name_in_bng ,:fathers_name,:mothers_name,
            :village,:post,:word_no, presence: true
  validate :nid_or_birthid_present

  validates_uniqueness_of :nid,:allow_blank => true, :allow_nil => true
  validates_uniqueness_of :birthid,:allow_blank => true, :allow_nil => true
  validates :nid, length: { minimum: 13 }

  def set_status(status)
    self.status = status
  end

  def active?
    self.status == :active
  end

  def pending?
    self.status == :pending
  end

  def save_requested_at
    self.requested_at = Time.now
  end

  def save_saved_at
    self.saved_at = Time.now
  end

  def requested_at_formatted
    return String.new unless requested_at.present?
    self.requested_at.strftime("%d-%m-%Y %I:%M:%S %p")
  end

  private

  def save_nid_birthdid_as_english
    if nid.present?
      self.nid = english_number(nid)
    end

    if birthid.present?
      self.birthid = english_number(birthid)
    end
  end

  def nid_or_birthid_present
    errors.add(:citizen," National Id or BirthId is required") unless nid.present? || birthid.present?
  end

end
