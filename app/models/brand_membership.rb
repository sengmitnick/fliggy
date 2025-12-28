class BrandMembership < ApplicationRecord
  belongs_to :user
  
  BRANDS = {
    'marriott' => '万豪会员',
    'hilton' => '希尔顿会员',
    'accor' => '雅高经典卡会员',
    'ihg' => 'IHG会员',
    'hyatt' => '凯悦会员'
  }.freeze
  
  STATUSES = %w[pending active inactive].freeze
  
  validates :brand_name, presence: true, inclusion: { in: BRANDS.keys }
  validates :status, inclusion: { in: STATUSES }
  
  def brand_display_name
    BRANDS[brand_name]
  end
end
