require 'rails_helper'

RSpec.describe "Bus ticket orders", type: :request do

  # Authentication required for bus_ticket_orders
  let(:user) { create(:user) }
  before { sign_in_as(user) }

  let!(:bus_ticket) { create(:bus_ticket) }

  describe "GET /bus_ticket_orders/new" do
    it "returns http success" do
      get new_bus_ticket_order_path(bus_ticket_id: bus_ticket.id)
      expect(response).to be_success_with_view_check('new')
    end
  end
  
end
