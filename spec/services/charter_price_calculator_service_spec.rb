require 'rails_helper'

RSpec.describe CharterPriceCalculatorService, type: :service do
  describe '#call' do
    it 'can be initialized and called' do
      route = create(:charter_route)
      vehicle_type = create(:vehicle_type)
      duration_hours = 8
      departure_date = Date.today
      
      service = CharterPriceCalculatorService.new(
        route: route,
        vehicle_type: vehicle_type,
        duration_hours: duration_hours,
        departure_date: departure_date
      )
      expect { service.call }.not_to raise_error
    end
  end
end
