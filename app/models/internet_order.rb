class InternetOrder < ApplicationRecord
  include DataVersionable
  belongs_to :user
  belongs_to :orderable, polymorphic: true

  before_create :generate_order_number

  validates :order_type, presence: true, inclusion: { in: %w[sim_card data_plan wifi] }
  validates :region, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :total_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true, inclusion: { in: %w[pending paid cancelled completed] }
  validates :delivery_method, inclusion: { in: %w[mail pickup], allow_nil: true }

  scope :pending, -> { where(status: 'pending') }
  scope :paid, -> { where(status: 'paid') }
  scope :completed, -> { where(status: 'completed') }
  scope :cancelled, -> { where(status: 'cancelled') }

  def sim_card?
    order_type == 'sim_card'
  end

  def data_plan?
    order_type == 'data_plan'
  end

  def wifi?
    order_type == 'wifi'
  end

  private

  def generate_order_number
    self.order_number = "IO#{Time.current.strftime('%Y%m%d%H%M%S')}#{SecureRandom.hex(4).upcase}"
  end
end
