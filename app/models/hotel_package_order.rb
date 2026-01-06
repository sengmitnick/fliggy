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
end
