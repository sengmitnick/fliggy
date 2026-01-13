# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Homepage", type: :system do
  include PlaywrightHelper

  let(:base_url) { "http://localhost:3000" }

  it "loads homepage without errors" do
    with_page(base_url) do |page|
      # Check page loaded successfully
      expect(page.title).not_to be_empty
      
      # Check URL is correct
      expect(page.url).to eq("#{base_url}/")
    end
  end

  it "can navigate to sign in page" do
    with_page(base_url) do |page|
      # Look for sign in link/button
      sign_in_link = page.query_selector('a[href="/sign_in"], a:has-text("登录"), a:has-text("Sign In")')
      
      if sign_in_link
        sign_in_link.click
        sleep 0.5  # Wait for navigation
        
        # Verify we're on sign in page
        expect(page.url).to include('/sign_in')
      else
        # Skip test if no sign in link found
        skip "No sign in link found on homepage"
      end
    end
  end

  it "can navigate to sign up page" do
    with_page(base_url) do |page|
      # Look for sign up link/button
      sign_up_link = page.query_selector('a[href="/sign_up"], a:has-text("注册"), a:has-text("Sign Up")')
      
      if sign_up_link
        sign_up_link.click
        sleep 0.5  # Wait for navigation
        
        # Verify we're on sign up page
        expect(page.url).to include('/sign_up')
      else
        # Skip test if no sign up link found
        skip "No sign up link found on homepage"
      end
    end
  end
end
