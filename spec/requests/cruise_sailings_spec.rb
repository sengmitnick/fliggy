require 'rails_helper'

RSpec.describe "Cruise sailings", type: :request do

  let(:user) { create(:user) }
  before { sign_in_as(user) }


  describe "GET /cruise_sailings/:id" do
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
      departure_port: 'Test Port A',
      arrival_port: 'Test Port B',
      status: 'on_sale',
      itinerary: []
    ) }

    it "returns http success" do
      get cruise_sailing_path(sailing)
      expect(response).to be_success_with_view_check('show')
    end
  end


end
