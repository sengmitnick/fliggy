require 'rails_helper'

RSpec.describe "Cruise orders", type: :request do

  let(:user) { create(:user) }
  before { sign_in_as(user) }

  let!(:cruise_line) { CruiseLine.create!(name: 'Test Line', name_en: 'Test Line EN', logo_url: 'test.jpg') }
  let!(:cruise_ship) { CruiseShip.create!(cruise_line: cruise_line, name: 'Test Ship', name_en: 'Test Ship EN', image_url: 'test.jpg', features: ['test']) }
  let!(:cruise_route) { CruiseRoute.create!(name: 'Test Route', region: 'japan_korea') }
  let!(:sailing) { CruiseSailing.create!(
    cruise_ship: cruise_ship,
    cruise_route: cruise_route,
    departure_date: Date.tomorrow,
    return_date: Date.tomorrow + 5.days,
    duration_days: 6,
    duration_nights: 5,
    departure_port: 'Test Port',
    arrival_port: 'Test Port',
    status: 'on_sale',
    itinerary: []
  ) }
  let!(:cabin_type) { CabinType.create!(
    cruise_ship: cruise_ship,
    name: 'Test Cabin',
    category: 'balcony',
    area: 20,
    has_balcony: true,
    has_window: true,
    max_occupancy: 2
  ) }
  let!(:product) { CruiseProduct.create!(
    cruise_sailing: sailing,
    cabin_type: cabin_type,
    merchant_name: 'Test Merchant',
    price_per_person: 1000,
    occupancy_requirement: 2,
    status: 'on_sale'
  ) }

  describe "GET /cruise_orders/new" do
    it "returns http success" do
      get new_cruise_order_path(product_id: product.id)
      expect(response).to be_success_with_view_check('new')
    end
  end
  
end
