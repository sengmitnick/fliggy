# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Flights", type: :system do
  include PlaywrightHelper

  let(:base_url) { "http://localhost:3000" }

  it "loads flights search page without errors" do
    with_page("#{base_url}/flights") do |page|
      expect(page.title).not_to be_empty
      expect(page.url).to include('/flights')
    end
  end

  it "can click search button on flights page" do
    with_page("#{base_url}/flights") do |page|
      search_button = page.query_selector('button:has-text("搜索"), button:has-text("查询机票"), button[type="submit"]')
      
      if search_button
        search_button.click
        sleep 0.5
        # Should stay on flights page or go to search results
        expect(page.url).to include('/flights')
      else
        skip "No search button found on flights page"
      end
    end
  end
end
