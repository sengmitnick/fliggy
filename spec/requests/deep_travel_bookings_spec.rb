require 'rails_helper'

RSpec.describe "Deep travel bookings", type: :request do

  # Uncomment this if controller need authentication
  # let(:user) { create(:user) }
  # before { sign_in_as(user) }



  describe "GET /deep_travel_bookings/new" do
    it "returns http success" do
      get new_deep_travel_booking_path
      expect(response).to be_success_with_view_check('new')
    end
  end
  
end
