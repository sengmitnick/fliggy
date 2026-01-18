require 'rails_helper'

RSpec.describe "Flight packages", type: :request do

  # Uncomment this if controller need authentication
  # let(:user) { create(:user) }
  # before { sign_in_as(user) }

  describe "GET /flight_packages" do
    it "returns http success" do
      get flight_packages_path
      expect(response).to be_success_with_view_check('index')
    end
  end

  describe "GET /flight_packages/:id" do
    let(:flight_package_record) { create(:flight_package) }


    it "returns http success" do
      get flight_package_path(flight_package_record)
      expect(response).to be_success_with_view_check('show')
    end
  end


end
