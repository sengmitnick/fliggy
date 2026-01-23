class CruiseLine < ApplicationRecord
  include DataVersionable
  extend FriendlyId
  friendly_id :name, use: :slugged
  
  has_many :cruise_ships, dependent: :destroy
  
  validates :name, presence: true, uniqueness: true
  validates :name_en, presence: true
end
