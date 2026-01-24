require 'rails_helper'

RSpec.describe "Bus ticket orders", type: :request do

  # Authentication required for bus_ticket_orders
  let(:user) { create(:user) }
  before { sign_in_as(user) }

  let!(:bus_ticket) { create(:bus_ticket) }
  let!(:passenger1) { create(:passenger, user: user, name: '张三', id_number: '110101199001011234', phone: '13800138000') }
  let!(:passenger2) { create(:passenger, user: user, name: '李四', id_number: '110101199001011235', phone: '13800138001') }

  describe "GET /bus_ticket_orders/new" do
    it "returns http success" do
      get new_bus_ticket_order_path(bus_ticket_id: bus_ticket.id)
      expect(response).to be_success_with_view_check('new')
    end
  end
  
  describe "POST /bus_ticket_orders" do
    context "with valid parameters" do
      let(:valid_params) do
        {
          bus_ticket_order: {
            bus_ticket_id: bus_ticket.id,
            passenger_ids: [passenger1.id, passenger2.id],
            insurance_type: 'refund'
          }
        }
      end
      
      it "creates one order with multiple passengers" do
        expect {
          post bus_ticket_orders_path, params: valid_params, as: :json
        }.to change(BusTicketOrder, :count).by(1)
         .and change(BusTicketPassenger, :count).by(2)
        
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        
        order = BusTicketOrder.last
        expect(order.passenger_count).to eq(2)
        expect(order.passengers.count).to eq(2)
        expect(order.total_price).to eq((bus_ticket.price * 2) + (9 * 2))
      end
    end
    
    context "with empty passenger_ids" do
      let(:invalid_params) do
        {
          bus_ticket_order: {
            bus_ticket_id: bus_ticket.id,
            passenger_ids: [],
            insurance_type: 'none'
          }
        }
      end
      
      it "returns error" do
        post bus_ticket_orders_path, params: invalid_params, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
      end
    end
  end
  
  describe "GET /bus_ticket_orders/:id/success" do
    let!(:order) do
      create(:bus_ticket_order, 
        user: user, 
        bus_ticket: bus_ticket,
        passenger_count: 2,
        base_price: bus_ticket.price,
        total_price: (bus_ticket.price * 2) + 18,
        insurance_type: 'refund',
        insurance_price: 18
      )
    end
    
    before do
      create(:bus_ticket_passenger, bus_ticket_order: order, passenger_name: '张三', passenger_id_number: '110101199001011234', insurance_type: 'refund')
      create(:bus_ticket_passenger, bus_ticket_order: order, passenger_name: '李四', passenger_id_number: '110101199001011235', insurance_type: 'refund')
    end
    
    it "displays order success page with multiple passengers" do
      get success_bus_ticket_order_path(order)
      expect(response).to be_success_with_view_check('success')
    end
  end
  
end
