require 'rails_helper'

RSpec.describe "Admin::BusTickets", type: :request do
  before { admin_sign_in_as(create(:administrator)) }

  describe "GET /admin/bus_tickets" do
    it "returns http success" do
      get admin_bus_tickets_path
      expect(response).to be_success_with_view_check('index')
    end
  end

end
