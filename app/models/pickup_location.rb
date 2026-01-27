class PickupLocation < ApplicationRecord
  include DataVersionable

  validates :city, presence: true
  validates :district, presence: true
  validates :detail, presence: true
  validates :phone, presence: true

  scope :active, -> { where(is_active: true) }
  scope :by_city, ->(city) { where(city: city) }

  def display_name
    "#{district} - #{detail.split("\n").first}"
  end

  def full_info
    "#{city}#{district} #{detail}"
  end
end
