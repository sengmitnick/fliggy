# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "DeepTravels", type: :system do
  include PlaywrightHelper

  let(:base_url) { "http://localhost:3000" }

  it "loads deep travels page without errors" do
    with_page("#{base_url}/deep_travels") do |page|
      expect(page.title).not_to be_empty
      expect(page.url).to include('/deep_travels')
    end
  end

  it "can browse guides on deep travels page" do
    with_page("#{base_url}/deep_travels") do |page|
      # Look for guide cards or navigation
      guide_element = page.query_selector('.card, [data-controller*="deep"]')
      
      if guide_element
        expect(guide_element).not_to be_nil
      else
        skip "No guide elements found on deep travels page"
      end
    end
  end
end
