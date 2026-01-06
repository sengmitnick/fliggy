require 'rails_helper'

RSpec.describe "Admin::TravelAgencies", type: :request do
  before { admin_sign_in_as(create(:administrator)) }

  describe "GET /admin/travel_agencies" do
    it "returns http success" do
      get admin_travel_agencies_path
      expect(response).to be_success_with_view_check('index')
    end
  end

end
