class Attraction < ApplicationRecord
  # Associations
  belongs_to :city
  has_many :route_attractions, dependent: :destroy
  has_many :charter_routes, through: :route_attractions

  # Validations
  validates :name, presence: true
  validates :city_id, presence: true
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true

  # Scopes
  scope :by_city, ->(city_id) { where(city_id: city_id) }
  scope :with_coordinates, -> { where.not(latitude: nil, longitude: nil) }
end
