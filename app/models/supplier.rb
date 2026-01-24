class Supplier < ApplicationRecord
  include DataVersionable
  
  has_many :ticket_suppliers, dependent: :destroy
  has_many :tickets, through: :ticket_suppliers
  has_many :ticket_orders, dependent: :nullify
  
  validates :name, presence: true
  validates :supplier_type, presence: true
  validates :rating, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }, allow_nil: true
  
  scope :by_type, ->(type) { where(supplier_type: type) if type.present? }
  scope :high_rating, -> { where("rating >= ?", 4.0) }
end
