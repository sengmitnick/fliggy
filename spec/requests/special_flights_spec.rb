require 'rails_helper'

RSpec.describe "SpecialFlights", type: :request do
  describe "GET /special_flights" do
    it "returns http success and renders the special flights search page" do
      get special_flights_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('特价机票')
      expect(response.body).to include('data-controller="special-flights date-picker"')
    end

    it "displays default departure and destination cities" do
      get special_flights_path
      expect(response.body).to include('深圳')
      expect(response.body).to include('杭州')
    end

    it "accepts custom departure and destination cities" do
      get special_flights_path, params: { departure_city: '北京', destination_cities: '上海,广州' }
      expect(response).to have_http_status(:success)
      expect(response.body).to include('北京')
      expect(response.body).to include('上海')
    end
  end

  describe "GET /special_flights/search" do
    it "redirects back when no destination cities provided" do
      get search_special_flights_path, params: { departure_city: '深圳', date: '2026-01-15' }
      expect(response).to redirect_to(special_flights_path)
      follow_redirect!
      expect(response.body).to include('请至少选择一个目的地城市')
    end

    it "accepts fuzzy date format" do
      get search_special_flights_path, params: { 
        departure_city: '深圳', 
        destination_cities: '杭州',
        date: 'fuzzy:2026-01,2026-02'
      }
      expect(response).to have_http_status(:success)
    end

    it "accepts exact date format" do
      get search_special_flights_path, params: { 
        departure_city: '深圳', 
        destination_cities: '杭州',
        date: '2026-01-15'
      }
      expect(response).to have_http_status(:success)
    end
  end
end
