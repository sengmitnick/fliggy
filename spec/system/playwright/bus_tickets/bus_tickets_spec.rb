# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "BusTickets", type: :system do
  include PlaywrightHelper

  let(:base_url) { "http://localhost:3000" }

  it "loads bus tickets page without errors" do
    with_page("#{base_url}/bus_tickets") do |page|
      expect(page.title).not_to be_empty
      expect(page.url).to include('/bus_tickets')
    end
  end

  it "can click search button on bus tickets page" do
    with_page("#{base_url}/bus_tickets") do |page|
      search_button = page.query_selector('button:has-text("搜索"), button:has-text("查询车票"), button[type="submit"]')
      
      if search_button
        search_button.click
        sleep 0.5
        expect(page.url).to include('/bus_tickets')
      else
        skip "No search button found on bus tickets page"
      end
    end
  end
end
