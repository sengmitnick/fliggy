class CruiseRoute < ApplicationRecord
  include DataVersionable
  
  has_many :cruise_sailings, dependent: :destroy
  
  validates :name, presence: true
  validates :region, presence: true
  
  # 航线区域常量
  REGIONS = {
    'japan_korea' => '日韩',
    'mediterranean' => '地中海',
    'alaska' => '阿拉斯加',
    'caribbean' => '加勒比',
    'north_pole' => '南北极',
    'southeast_asia' => '东南亚',
    'europe_river' => '欧洲河轮',
    'middle_east' => '中东',
    'xisha_islands' => '西沙群岛'
  }.freeze
  
  def region_name
    REGIONS[region] || region
  end
end
