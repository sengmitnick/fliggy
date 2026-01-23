require 'rails_helper'

RSpec.describe "Charter bookings", type: :request do

  let(:user) { create(:user) }
  before { sign_in_as(user) }


  describe "GET /charter_bookings/:id" do
    let(:charter_booking_record) { create(:charter_booking, user: user) }


    it "returns http success" do
      get charter_booking_path(charter_booking_record)
      expect(response).to be_success_with_view_check('show')
    end
  end

  describe "GET /charter_bookings/new" do
    let(:route) { create(:charter_route) }
    let(:vehicle_type) { create(:vehicle_type) }
    
    it "returns http success" do
      get new_charter_booking_path, params: {
        route_id: route.id,
        vehicle_type_id: vehicle_type.id,
        departure_date: Date.today + 1.day,
        duration_hours: 8,
        passengers_count: 4,
        total_price: 800
      }
      expect(response).to be_success_with_view_check('new')
    end
  end
  
end
