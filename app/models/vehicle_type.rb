class VehicleType < ApplicationRecord
  # Associations
  has_many :charter_bookings, dependent: :restrict_with_error

  # Validations
  validates :name, presence: true
  validates :category, presence: true, inclusion: { in: %w[5座 7座 巴士] }
  validates :level, presence: true, inclusion: { in: %w[经济 舒适 豪华] }
  validates :seats, presence: true, numericality: { greater_than: 0 }
  validates :luggage_capacity, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :hourly_price_6h, presence: true, numericality: { greater_than: 0 }
  validates :hourly_price_8h, presence: true, numericality: { greater_than: 0 }
  validates :included_mileage, presence: true, numericality: { greater_than: 0 }

  # Scopes
  scope :by_category, ->(category) { where(category: category) }
  scope :by_level, ->(level) { where(level: level) }
  scope :seats_5, -> { where(category: '5座') }
  scope :seats_7, -> { where(category: '7座') }
  scope :bus, -> { where(category: '巴士') }
  scope :economy, -> { where(level: '经济') }
  scope :comfort, -> { where(level: '舒适') }
  scope :luxury, -> { where(level: '豪华') }

  # Instance methods
  def price_for_duration(hours)
    case hours
    when 6
      hourly_price_6h
    when 8
      hourly_price_8h
    else
      raise ArgumentError, "Invalid duration: #{hours}. Must be 6 or 8."
    end
  end

  def display_name
    "#{level}#{category}"
  end
end
