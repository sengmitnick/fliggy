require 'rails_helper'

RSpec.describe "Cruises", type: :request do

  let(:user) { create(:user) }
  before { sign_in_as(user) }

  describe "GET /cruises" do
    it "returns http success" do
      get cruises_path
      expect(response).to be_success_with_view_check('index')
    end
  end

  describe "GET /cruises/:id" do
    let!(:cruise_line) { CruiseLine.create!(name: 'Test Line', name_en: 'Test Line EN', logo_url: 'https://via.placeholder.com/150') }
    let!(:cruise_ship) { CruiseShip.create!(cruise_line: cruise_line, name: 'Test Ship', name_en: 'Test Ship EN', image_url: 'https://via.placeholder.com/600x400', features: ['test']) }

    it "returns http success" do
      get cruise_path(cruise_ship.slug)
      expect(response).to be_success_with_view_check('show')
    end
  end


end
