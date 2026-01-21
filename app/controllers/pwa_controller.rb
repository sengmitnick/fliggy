class PwaController < ApplicationController
  # Skip browser version check for PWA files
  skip_before_action :verify_authenticity_token
  allow_browser versions: :all
  
  def manifest
    manifest_data = {
      name: Rails.application.config.x.appname,
      short_name: Rails.application.config.x.appname,
      icons: [
        {
          src: view_context.asset_path('app-favicon.svg'),
          type: 'image/svg+xml',
          sizes: 'any'
        },
        {
          src: view_context.asset_path('app-favicon.svg'),
          type: 'image/svg+xml',
          sizes: 'any',
          purpose: 'maskable'
        }
      ],
      start_url: '/',
      display: 'standalone',
      scope: '/',
      description: "#{Rails.application.config.x.appname} - A Progressive Web App built with Rails",
      theme_color: '#ffc105',
      background_color: '#ffc105',
      orientation: 'any',
      categories: ['productivity', 'utilities']
    }
    render json: manifest_data, content_type: 'application/manifest+json'
  end

  def service_worker
    expires_in 0.seconds, public: true
    render 'pwa/service_worker', layout: false, content_type: 'application/javascript'
  end

  def assetlinks
    # Digital Asset Links for TWA (Trusted Web Activities)
    # This file verifies domain ownership for Android apps
    assetlinks_data = [
      {
        relation: ["delegate_permission/common.handle_all_urls"],
        target: {
          namespace: "android_app",
          package_name: "ai.clacky.trip01",
          sha256_cert_fingerprints: [
            # SHA256 fingerprint from android.keystore
            # Generate with: keytool -list -v -keystore android.keystore -alias android -storepass android -keypass android
            # TODO: Client should update this with their actual keystore fingerprint
            "00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00"
          ]
        }
      }
    ]
    render json: assetlinks_data, content_type: 'application/json'
  end
end
