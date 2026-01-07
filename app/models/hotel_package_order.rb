class HotelPackageOrder < ApplicationRecord
  belongs_to :hotel_package
  belongs_to :package_option
  belongs_to :user
  belongs_to :passenger

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :total_price, presence: true
  validates :booking_type, inclusion: { in: %w[stockup instant] }
  validates :contact_name, presence: true
  validates :contact_phone, presence: true

  before_create :generate_order_number
  before_create :set_purchased_at
  before_create :set_valid_until

  private

  def generate_order_number
    self.order_number = "HP#{Time.current.strftime('%Y%m%d%H%M%S')}#{SecureRandom.hex(4).upcase}"
  end

  def set_purchased_at
    self.purchased_at = Time.current if status == 'paid'
  end

  def set_valid_until
    # Set validity to 1 year from purchase date
    self.valid_until = 1.year.from_now if status == 'paid'
  end
end
