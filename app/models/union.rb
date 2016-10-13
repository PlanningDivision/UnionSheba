class Union < ActiveRecord::Base
  belongs_to :upazila
  has_many :citizens
  has_many :trade_organizations

  def to_s
    name_in_bng
  end
end
