require 'rails_helper'

RSpec.describe "Attraction activities", type: :request do

  let(:user) { create(:user) }
  before { sign_in_as(user) }

  # No user-facing routes for attraction_activities
  # Activities are accessed through their parent attraction

end
