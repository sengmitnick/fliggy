require 'rails_helper'

RSpec.describe "Trains", type: :request do

  # Uncomment this if controller need authentication
  # let(:user) { create(:user) }
  # before { sign_in_as(user) }

  describe "GET /trains" do
    it "returns http success" do
      get trains_path
      expect(response).to be_success_with_view_check('index')
    end
  end

  describe "GET /trains/search" do
    context "when searching Beijing to Shanghai route" do
      it "displays departure city (Beijing)" do
        get search_trains_path(departure_city: "北京", arrival_city: "上海")
        expect(response).to be_success_with_view_check('search')
        expect(response.body).to include("北京")
      end

      it "displays arrival city (Shanghai)" do
        get search_trains_path(departure_city: "北京", arrival_city: "上海")
        expect(response).to be_success_with_view_check('search')
        expect(response.body).to include("上海")
      end
    end

    context "when searching Shanghai to Hangzhou route" do
      it "displays departure city (Shanghai)" do
        get search_trains_path(departure_city: "上海", arrival_city: "杭州")
        expect(response).to be_success_with_view_check('search')
        expect(response.body).to include("上海")
      end

      it "displays arrival city (Hangzhou)" do
        get search_trains_path(departure_city: "上海", arrival_city: "杭州")
        expect(response).to be_success_with_view_check('search')
        expect(response.body).to include("杭州")
      end
    end

    context "when searching with unknown city" do
      it "falls back to using city name as station" do
        get search_trains_path(departure_city: "未知城市", arrival_city: "上海")
        expect(response).to be_success_with_view_check('search')
        expect(response.body).to include("未知城市")
      end
    end
  end



end
