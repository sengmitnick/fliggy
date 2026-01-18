class Destination < ApplicationRecord
  include DataVersionable
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  has_many :tour_products, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :region, presence: true

  scope :hot_destinations, -> { where(is_hot: true) }
  scope :by_region, ->(region) { where(region: region) }

  def slug_candidates
    [
      :pinyin_slug,
      [:pinyin_slug, :id]
    ]
  end

  def pinyin_slug
    PinYin.of_string(name).join('-').downcase.gsub(/[^a-z0-9]+/, '-').gsub(/^-|-$/, '')
  end
end
