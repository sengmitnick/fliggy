class AbroadTicketOrder < ApplicationRecord
  belongs_to :user
  belongs_to :abroad_ticket

  validates :passenger_name, presence: true
  validates :contact_phone, presence: true
  validates :contact_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :passenger_type, presence: true
  validates :seat_category, presence: true
  validates :total_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true, inclusion: { in: %w[pending paid cancelled completed] }

  before_create :generate_order_number

  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :recent, -> { order(created_at: :desc) }

  private

  def generate_order_number
    self.order_number = "ABT#{Time.current.strftime('%Y%m%d')}#{SecureRandom.hex(4).upcase}"
  end
end
