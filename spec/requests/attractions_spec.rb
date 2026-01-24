require 'rails_helper'

RSpec.describe "Attractions", type: :request do

  let(:user) { create(:user) }
  before { sign_in_as(user) }

  describe "GET /attractions" do
    it "returns http success" do
      get attractions_path
      expect(response).to be_success_with_view_check('index')
    end
  end

  describe "GET /attractions/:id" do
    let(:attraction_record) { create(:attraction) }


    it "returns http success" do
      get attraction_path(attraction_record)
      expect(response).to be_success_with_view_check('show')
    end
  end


end
