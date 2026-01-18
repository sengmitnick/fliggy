class Country < ApplicationRecord
  include DataVersionable
  extend FriendlyId
  friendly_id :name, use: [:slugged, :history]

  has_many :visa_products, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :code, presence: true, uniqueness: true
  validates :region, presence: true
  
  def should_generate_new_friendly_id?
    name_changed? || super
  end
end
