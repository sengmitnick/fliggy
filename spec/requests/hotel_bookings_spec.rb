require 'rails_helper'

RSpec.describe "Hotel bookings", type: :request do

  # Uncomment this if controller need authentication
  # let(:user) { create(:user) }
  # before { sign_in_as(user) }


  describe "GET /hotel_bookings/:id" do
    let(:hotel_booking_record) { create(:hotel_booking) }


    it "returns http success" do
      get hotel_booking_path(hotel_booking_record)
      expect(response).to be_success_with_view_check('show')
    end
  end

  describe "GET /hotel_bookings/new" do
    let(:hotel) { create(:hotel) }
    let(:hotel_room) { create(:hotel_room, hotel: hotel) }
    
    it "returns http success" do
      get new_hotel_hotel_booking_path(hotel_id: hotel.id, room_id: hotel_room.id)
      expect(response).to be_success_with_view_check('new')
    end
  end
  
end
