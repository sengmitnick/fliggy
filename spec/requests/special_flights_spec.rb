require 'rails_helper'

RSpec.describe "SpecialFlights", type: :request do
  describe "GET /special_flights" do
    it "returns http success and renders the special flights search page" do
      get special_flights_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('特价机票')
      expect(response.body).to include('data-controller="special-flights')
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

    it "search form redirects to flights/search with sort_by=price" do
      get special_flights_path
      expect(response.body).to include('action="/flights/search"')
      expect(response.body).to include('value="price"')
    end
  end
end
