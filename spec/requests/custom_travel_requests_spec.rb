require 'rails_helper'

RSpec.describe 'CustomTravelRequests', type: :request do
  describe 'POST /custom_travel_requests' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          custom_travel_request: {
            departure_city: '上海',
            destination_city: '湖南',
            adults_count: 2,
            children_count: 0,
            elders_count: 0,
            days_count: 3,
            departure_date: Date.today + 1.day,
            phone: '13800138000',
            expected_merchants: 1,
            preferences: '喜欢自然风光和当地美食'
          }
        }
      end

      it 'creates a new custom travel request' do
        expect {
          post custom_travel_requests_path, params: valid_params
        }.to change(CustomTravelRequest, :count).by(1)
      end

      it 'redirects to the show page' do
        post custom_travel_requests_path, params: valid_params
        expect(response).to redirect_to(custom_travel_request_path(CustomTravelRequest.last))
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          custom_travel_request: {
            departure_city: '上海',
            destination_city: '',  # Missing required field
            adults_count: 2,
            phone: '123',  # Invalid phone
            days_count: 3,
            expected_merchants: 1
          }
        }
      end

      it 'does not create a new custom travel request' do
        expect {
          post custom_travel_requests_path, params: invalid_params
        }.not_to change(CustomTravelRequest, :count)
      end

      it 'returns unprocessable entity status' do
        post custom_travel_requests_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'GET /custom_travel_requests/:id' do
    let!(:custom_travel_request) do
      CustomTravelRequest.create!(
        departure_city: '上海',
        destination_city: '湖南',
        adults_count: 2,
        children_count: 0,
        elders_count: 0,
        days_count: 3,
        departure_date: Date.today + 1.day,
        phone: '13800138000',
        expected_merchants: 1,
        preferences: '喜欢自然风光和当地美食'
      )
    end

    it 'returns a successful response' do
      get custom_travel_request_path(custom_travel_request)
      expect(response).to be_successful
    end

    it 'displays the order details' do
      get custom_travel_request_path(custom_travel_request)
      expect(response.body).to include('定制游订单')
      expect(response.body).to include('湖南')
      expect(response.body).to include('上海')
    end

    it 'displays the merchant information' do
      get custom_travel_request_path(custom_travel_request)
      expect(response.body).to include('湖南途时光旅游专营店')
    end

    it 'displays the progress steps' do
      get custom_travel_request_path(custom_travel_request)
      expect(response.body).to include('沟通方案')
      expect(response.body).to include('确认方案')
      expect(response.body).to include('预订支付')
      expect(response.body).to include('出行游玩')
    end
  end
end
