require 'rails_helper'

RSpec.describe "Admin::CharterBookings", type: :request do
  before { admin_sign_in_as(create(:administrator)) }

  describe "GET /admin/charter_bookings" do
    it "returns http success" do
      get admin_charter_bookings_path
      expect(response).to be_success_with_view_check('index')
    end
  end

end
