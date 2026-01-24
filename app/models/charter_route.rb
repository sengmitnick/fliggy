class CharterRoute < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  serialize :highlights, coder: JSON

  # Associations
  belongs_to :city
  has_many :route_attractions, dependent: :destroy
  has_many :attractions, through: :route_attractions
  has_many :charter_bookings, dependent: :restrict_with_error

  # Validations
  validates :name, presence: true
  validates :city_id, presence: true
  validates :duration_days, presence: true, numericality: { greater_than: 0 }
  validates :distance_km, presence: true, numericality: { greater_than: 0 }
  validates :category, presence: true, inclusion: { in: %w[featured classic hot] }
  validates :price_from, presence: true, numericality: { greater_than: 0 }

  # Scopes
  scope :by_city, ->(city_id) { where(city_id: city_id) }
  scope :by_category, ->(category) { where(category: category) }
  scope :featured, -> { where(category: 'featured') }
  scope :classic, -> { where(category: 'classic') }
  scope :hot, -> { where(category: 'hot') }
  scope :by_duration, ->(days) { where(duration_days: days) }

  # Instance methods
  def attractions_count
    route_attractions.count
  end

  def estimated_duration_text
    if duration_days == 1
      "1日游"
    else
      "#{duration_days}日#{duration_days - 1}夜"
    end
  end
end
