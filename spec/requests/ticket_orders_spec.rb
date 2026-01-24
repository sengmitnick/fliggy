require 'rails_helper'

RSpec.describe "Ticket orders", type: :request do

  let(:user) { create(:user) }
  before { sign_in_as(user) }


  describe "GET /ticket_orders/:id" do
    let(:ticket_order_record) { create(:ticket_order, user: user) }


    it "returns http success" do
      get ticket_order_path(ticket_order_record)
      expect(response).to be_success_with_view_check('show')
    end
  end

  describe "GET /ticket_orders/new" do
    let(:ticket) { create(:ticket) }
    
    it "returns http success" do
      get new_ticket_ticket_order_path(ticket)
      expect(response).to be_success_with_view_check('new')
    end
  end
  
end
