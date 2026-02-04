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
      it "displays Beijing stations as departure stations" do
        get search_trains_path(departure_city: "北京", arrival_city: "上海")
        expect(response).to be_success_with_view_check('search')
        expect(response.body).to include("北京站")
        expect(response.body).to include("北京西站")
        expect(response.body).to include("北京南站")
        expect(response.body).to include("北京北站")
      end

      it "displays Shanghai stations as arrival stations" do
        get search_trains_path(departure_city: "北京", arrival_city: "上海")
        expect(response).to be_success_with_view_check('search')
        expect(response.body).to include("上海站")
        expect(response.body).to include("上海虹桥站")
        expect(response.body).to include("上海南站")
      end
    end

    context "when searching Shanghai to Hangzhou route" do
      it "displays Shanghai stations as departure stations" do
        get search_trains_path(departure_city: "上海", arrival_city: "杭州")
        expect(response).to be_success_with_view_check('search')
        expect(response.body).to include("上海站")
        expect(response.body).to include("上海虹桥站")
        expect(response.body).to include("上海南站")
      end

      it "displays Hangzhou stations as arrival stations" do
        get search_trains_path(departure_city: "上海", arrival_city: "杭州")
        expect(response).to be_success_with_view_check('search')
        expect(response.body).to include("杭州站")
        expect(response.body).to include("杭州东站")
        expect(response.body).to include("杭州南站")
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
