require 'rails_helper'

RSpec.describe "Charter routes", type: :request do

  let(:user) { create(:user) }
  before { sign_in_as(user) }


  describe "GET /charter_routes/:id" do
    let(:charter_route_record) { create(:charter_route, user: user) }


    it "returns http success" do
      get charter_route_path(charter_route_record)
      expect(response).to be_success_with_view_check('show')
    end
  end


end
