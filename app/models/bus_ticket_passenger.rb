class BusTicketPassenger < ApplicationRecord
  belongs_to :bus_ticket_order
  
  validates :passenger_name, :passenger_id_number, presence: true
  validates :insurance_type, inclusion: { in: %w[none refund premium], allow_nil: true }
end
