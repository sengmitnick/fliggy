require 'rails_helper'

RSpec.describe "Destinations", type: :request do

  # Uncomment this if controller need authentication
  # let(:user) { create(:user) }
  # before { sign_in_as(user) }

  # destinations#index redirects to a specific city, so we skip testing it
  # The redirect logic depends on data packs being loaded

  describe "GET /destinations/:id" do
    it "returns http success" do
      # Rely on data packs loaded by validators
      destination = Destination.find_by(name: '深圳') || Destination.find_by(name: '深圳市') || Destination.first
      skip "No destinations available in data packs" unless destination
      
      get destination_path(destination)
      expect(response).to be_success_with_view_check('show')
    end
  end


end
