class TicketOrder < ApplicationRecord
  include DataVersionable
  belongs_to :user
  belongs_to :ticket
  belongs_to :supplier, optional: true
  belongs_to :passenger, optional: true
  
  # Support multiple passengers
  def passengers
    return [] if passenger_ids.blank?
    Passenger.where(id: passenger_ids)
  end
  
  validates :contact_phone, presence: true
  validates :visit_date, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :total_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: %w[pending paid confirmed completed cancelled refunded] }
  
  before_validation :generate_order_number, on: :create
  before_validation :calculate_total_price, on: :create
  
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :recent, -> { order(created_at: :desc) }
  
  private
  
  def generate_order_number
    self.order_number ||= "TO#{Time.current.strftime('%Y%m%d%H%M%S')}#{SecureRandom.hex(4).upcase}"
  end
  
  def calculate_total_price
    if supplier && ticket
      ticket_supplier = TicketSupplier.find_by(ticket_id: ticket.id, supplier_id: supplier.id)
      self.total_price = (ticket_supplier&.current_price || ticket.current_price) * quantity
    elsif ticket && quantity
      self.total_price = ticket.current_price * quantity
    end
  end
end
