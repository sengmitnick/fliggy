class TransferLocation < ApplicationRecord
  include DataVersionable
  
  validates :city, :name, presence: true
  validates :location_type, presence: true, inclusion: { in: %w[airport train_station other] }
  
  scope :by_city, ->(city) { where(city: city) }
  scope :airports, -> { where(location_type: 'airport') }
  scope :train_stations, -> { where(location_type: 'train_station') }
  scope :others, -> { where(location_type: 'other') }
  
  # 按城市分类获取地点
  def self.locations_by_city(city)
    locations = by_city(city)
    {
      airports: locations.airports.pluck(:name),
      train_stations: locations.train_stations.pluck(:name),
      others: locations.others.pluck(:name)
    }
  end
end
