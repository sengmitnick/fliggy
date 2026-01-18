class FamilyCoupon < ApplicationRecord
  # Validations
  validates :title, presence: true
  validates :coupon_type, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: %w[available used expired] }
  
  # Scopes
  scope :available, -> { where(status: 'available').where('valid_until >= ?', Date.today) }
  scope :used, -> { where(status: 'used') }
  scope :expired, -> { where(status: 'expired') }
  scope :by_type, ->(type) { where(coupon_type: type) }
  
  # Instance methods
  def expired?
    valid_until && valid_until < Date.today
  end
  
  def available?
    status == 'available' && !expired?
  end
end
