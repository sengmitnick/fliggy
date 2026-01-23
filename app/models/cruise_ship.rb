class CruiseShip < ApplicationRecord
  include DataVersionable
  extend FriendlyId
  friendly_id :name, use: :slugged
  
  belongs_to :cruise_line
  has_many :cruise_sailings, dependent: :destroy
  has_many :cabin_types, dependent: :destroy
  
  validates :name, presence: true
  validates :name_en, presence: true
  
  # 获取特色标签
  def feature_list
    features.is_a?(Array) ? features : []
  end
end
