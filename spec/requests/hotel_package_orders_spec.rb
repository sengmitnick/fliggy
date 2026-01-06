require 'rails_helper'

RSpec.describe "Hotel package orders", type: :request do
  let(:user) { create(:user) }
  let(:package) { create(:hotel_package) }
  let(:package_option) { create(:package_option, hotel_package: package) }
  let(:passenger) { create(:passenger, user: user) }

  before { sign_in_as(user) }

  describe "GET /hotel_package_orders/new" do
    it "returns http success" do
      get new_hotel_package_order_path(package_option_id: package_option.id)
      expect(response).to be_success_with_view_check('new')
    end
  end

  describe "GET /hotel_package_orders/:id" do
    let(:hotel_package_order) do
      create(:hotel_package_order,
             user: user,
             hotel_package: package,
             package_option: package_option,
             passenger: passenger)
    end

    it "returns http success" do
      get hotel_package_order_path(hotel_package_order)
      expect(response).to be_success_with_view_check('show')
    end
  end
end
