class Address < ActiveRecord::Base
  belongs_to :addressable, polymorphic: true

  validates :village, :word_no, :post_office,:district,:upazila, presence: true

  scope :present, -> (lang) {
    where(address_type: :present, lang: lang)
  }

  scope :permanent, -> (lang) {
    where(address_type: :permanent, lang: lang)
  }

  def present_address?
    return self.address_type == 'present'
  end

  def permanent_address?
    return self.address_type == 'permanent'
  end

end
