require 'rails_helper'

RSpec.describe "Bookings", type: :request do

  let(:user) { create(:user) }
  before { sign_in_as(user) }



  describe "GET /bookings/new" do
    it "returns http success" do
      get new_booking_path
      expect(response).to be_success_with_view_check('new')
    end
  end
  
end
