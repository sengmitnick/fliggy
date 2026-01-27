require 'rails_helper'

RSpec.describe "Internet orders", type: :request do
  let(:user) { create(:user) }
  let(:wifi) { InternetWifi.create!(name: 'Test WiFi', daily_price: 25, network_type: '4G', deposit: 500, region: '中国香港') }
  
  before { sign_in_as(user) }

  describe "GET /internet_orders/new" do
    it "returns http success" do
      get new_internet_order_path(orderable_type: 'InternetWifi', orderable_id: wifi.id, region: '中国香港')
      expect(response).to be_success_with_view_check('new')
    end
  end
  
  describe "POST /internet_orders" do
    let(:valid_params) do
      {
        internet_order: {
          orderable_id: wifi.id,
          orderable_type: 'InternetWifi',
          order_type: 'wifi',
          region: '中国香港',
          quantity: 1,
          total_price: 25,
          delivery_method: 'mail'
        }
      }
    end
    
    context "with JSON format" do
      it "creates order with pending status and returns payment URLs" do
        post internet_orders_path, params: valid_params, as: :json
        
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['order_id']).to be_present
        expect(json['payment_url']).to include('/pay')
        expect(json['success_url']).to include('/success')
        
        order = InternetOrder.find(json['order_id'])
        expect(order.status).to eq('pending')
      end
    end
  end
  
  describe "PATCH /internet_orders/:id/pay" do
    let(:order) { InternetOrder.create!(user: user, orderable: wifi, order_type: 'wifi', region: '中国香港', quantity: 1, total_price: 25, status: 'pending') }
    
    it "updates order status to paid" do
      patch pay_internet_order_path(order), as: :json
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      
      order.reload
      expect(order.status).to eq('paid')
    end
  end
  
  describe "GET /internet_orders/:id/success" do
    let(:order) { InternetOrder.create!(user: user, orderable: wifi, order_type: 'wifi', region: '中国香港', quantity: 1, total_price: 25, status: 'paid') }
    
    it "returns http success" do
      get success_internet_order_path(order)
      expect(response).to be_success_with_view_check('success')
    end
  end
end
