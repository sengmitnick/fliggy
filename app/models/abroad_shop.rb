class AbroadShop < ApplicationRecord
  belongs_to :abroad_brand
  has_many :abroad_coupons, dependent: :destroy

  validates :name, presence: true
  validates :city, presence: true

  scope :by_city, ->(city) { where(city: city) if city.present? }
end
