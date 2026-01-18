class AbroadTicket < ApplicationRecord
  include DataVersionable
  has_many :abroad_ticket_orders, dependent: :destroy

  validates :region, presence: true, inclusion: { in: %w[japan europe] }
  validates :ticket_type, presence: true, inclusion: { in: %w[train pass card] }
  validates :origin, :destination, :departure_date, presence: true
  validates :time_slot_start, :time_slot_end, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :by_region, ->(region) { where(region: region) if region.present? }
  scope :by_ticket_type, ->(ticket_type) { where(ticket_type: ticket_type) if ticket_type.present? }
  scope :by_route, ->(origin, destination) { where(origin: origin, destination: destination) if origin.present? && destination.present? }
  scope :by_date, ->(date) { where(departure_date: date) if date.present? }
  scope :available, -> { where(status: 'available') }

  def duration_minutes
    return nil unless time_slot_start.present? && time_slot_end.present?
    start_time = Time.parse(time_slot_start)
    end_time = Time.parse(time_slot_end)
    ((end_time - start_time) / 60).to_i
  end
end
