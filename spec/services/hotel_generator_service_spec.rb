require 'rails_helper'

RSpec.describe HotelGeneratorService, type: :service do
  describe '#call' do
    it 'can be initialized and called' do
      # Create a test user for the service to use
      User.create!(email: 'test@example.com', password: 'password123', password_confirmation: 'password123') unless User.exists?(email: 'test@example.com')
      
      service = HotelGeneratorService.new
      expect { service.call }.not_to raise_error
    end
  end
end
