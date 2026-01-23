class RouteAttraction < ApplicationRecord
  # Associations
  belongs_to :charter_route
  belongs_to :attraction

  # Validations
  validates :charter_route_id, presence: true
  validates :attraction_id, presence: true
  validates :position, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Scopes
  scope :ordered, -> { order(:position) }

  # Default scope
  default_scope { ordered }
end
