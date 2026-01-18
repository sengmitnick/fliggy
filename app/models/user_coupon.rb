class UserCoupon < ApplicationRecord
  include DataVersionable
  belongs_to :user
  belongs_to :abroad_coupon

  validates :status, presence: true, inclusion: { in: %w[unclaimed claimed used expired] }

  scope :unclaimed, -> { where(status: 'unclaimed') }
  scope :claimed, -> { where(status: 'claimed') }
  scope :used, -> { where(status: 'used') }
  scope :expired, -> { where(status: 'expired') }
  scope :usable, -> { where(status: 'claimed').where('expires_at >= ?', Time.current) }

  def claim!
    update!(status: 'claimed', claimed_at: Time.current)
  end

  def use!
    update!(status: 'used', used_at: Time.current)
  end

  def expired?
    expires_at && expires_at < Time.current
  end
end
