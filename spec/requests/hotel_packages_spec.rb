require 'rails_helper'

RSpec.describe "Hotel packages", type: :request do

  # Uncomment this if controller need authentication
  # let(:user) { create(:user) }
  # before { sign_in_as(user) }

  describe "GET /hotel_packages" do
    it "returns http success" do
      get hotel_packages_path
      expect(response).to be_success_with_view_check('index')
    end
  end

  describe "GET /hotel_packages/search" do
    it "returns http success" do
      get search_hotel_packages_path
      expect(response).to be_success_with_view_check('search')
    end
  end

  describe "GET /hotel_packages/:id" do
    let(:hotel_package) { HotelPackage.create!(
      brand_name: "华住",
      title: "测试套餐",
      price: 500,
      original_price: 800,
      valid_days: 180,
      package_type: "standard",
      description: "测试描述"
    ) }

    it "returns http success" do
      get hotel_package_path(hotel_package)
      expect(response).to be_success_with_view_check('show')
    end
  end



end
