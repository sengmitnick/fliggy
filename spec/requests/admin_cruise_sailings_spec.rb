require 'rails_helper'

RSpec.describe "Admin::CruiseSailings", type: :request do
  before { admin_sign_in_as(create(:administrator)) }

  describe "GET /admin/cruise_sailings" do
    it "returns http success" do
      get admin_cruise_sailings_path
      expect(response).to be_success_with_view_check('index')
    end
  end

end
