class BusTicket < ApplicationRecord
  has_many :bus_ticket_orders, dependent: :destroy
  
  validates :origin, :destination, :departure_date, :departure_time, :price, presence: true
  
  scope :search, ->(origin, destination, date) {
    where(origin: origin, destination: destination, departure_date: date)
      .where(status: 'available')
  }
  
  def duration_minutes
    return nil unless arrival_time && departure_time
    departure = Time.parse(departure_time)
    arrival = Time.parse(arrival_time)
    ((arrival - departure) / 60).to_i
  end
end
