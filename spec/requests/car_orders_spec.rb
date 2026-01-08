require 'rails_helper'

RSpec.describe "Car orders", type: :request do

  # Uncomment this if controller need authentication
  # let(:user) { create(:user) }
  # before { sign_in_as(user) }



  describe "GET /car_orders/new" do
    it "returns http success" do
      car = Car.create!(
        brand: 'Test Brand',
        car_model: 'Test Model',
        seats: 5,
        fuel_type: '汽油',
        transmission: '自动挡',
        price_per_day: 100,
        pickup_location: 'Test Location'
      )
      get new_car_order_path(car_id: car.id)
      expect(response).to be_success_with_view_check('new')
    end
  end
  
end
