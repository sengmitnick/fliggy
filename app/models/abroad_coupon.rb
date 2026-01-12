class AbroadCoupon < ApplicationRecord
  belongs_to :abroad_brand
  belongs_to :abroad_shop, optional: true
  has_many :user_coupons, dependent: :destroy

  validates :title, presence: true
  validates :discount_type, presence: true

  scope :active, -> { where(active: true).where('valid_until >= ?', Date.today) }
  scope :for_brand, ->(brand_id) { where(abroad_brand_id: brand_id) }
  scope :for_shop, ->(shop_id) { where(abroad_shop_id: shop_id) }

  def still_valid?
    active && valid_until >= Date.today
  end
end
