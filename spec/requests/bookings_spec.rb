require 'rails_helper'

RSpec.describe "Bookings", type: :request do

  let(:user) { create(:user) }
  let(:flight) { Flight.first || create(:flight) }
  before { sign_in_as(user) }

  describe "GET /bookings" do
    it "returns http success" do
      get bookings_path
      expect(response).to be_success_with_view_check('index')
    end

    it "displays bookings for current user" do
      booking = Booking.create!(
        user: user,
        flight: flight,
        passenger_name: "测试用户",
        passenger_id_number: "110101199001011234",
        contact_phone: "13800138000",
        total_price: 500.00,
        status: "paid",
        trip_type: "one_way",
        accept_terms: true
      )
      get bookings_path
      expect(response.body).to include(booking.flight.departure_city)
      expect(response.body).to include(booking.flight.destination_city)
    end

    it "filters bookings by status" do
      Booking.create!(
        user: user,
        flight: flight,
        passenger_name: "测试用户",
        passenger_id_number: "110101199001011234",
        contact_phone: "13800138000",
        total_price: 500.00,
        status: "pending",
        trip_type: "one_way",
        accept_terms: true
      )
      get bookings_path(status: 'pending')
      expect(response).to be_success_with_view_check('index')
    end
  end

  describe "GET /bookings/new" do
    it "returns http success" do
      get new_booking_path(flight_id: flight.id)
      expect(response).to be_success_with_view_check('new')
    end
  end
  
end
