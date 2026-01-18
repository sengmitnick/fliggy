class AbroadBrand < ApplicationRecord
  include DataVersionable
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_many :abroad_shops, dependent: :destroy
  has_many :abroad_coupons, dependent: :destroy

  validates :name, presence: true
  validates :category, presence: true

  scope :featured, -> { where(featured: true) }
  scope :duty_free, -> { where(category: 'duty_free') }
  scope :cosmeceuticals, -> { where(category: 'cosmeceuticals') }
  scope :department_store, -> { where(category: 'department_store') }

  def category_text
    case category
    when 'duty_free' then '免税店'
    when 'cosmeceuticals' then '药妆专享'
    when 'department_store' then '百货商场'
    else category
    end
  end
end
