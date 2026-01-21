# frozen_string_literal: true

# This concern automatically adds status: :unprocessable_entity to render calls
# when the request is a form submission (POST/PATCH/PUT) and no status is explicitly provided.
# This prevents Turbo from throwing "Form responses must redirect to another location" error.
#
# Note: This only applies to form error cases (render :new, render :edit, etc.)
# It does NOT apply to explicit turbo_stream renders (render turbo_stream: ...)
module TurboCompatibleRenderConcern
  extend ActiveSupport::Concern

  def render(*args, **options, &block)
    # Only apply Turbo-compatible status to HTML form submissions
    # Skip for: JSON, JS, CSS, XML, Turbo Stream, and explicit status
    should_add_status = request.post? || request.patch? || request.put?
    should_add_status &&= request.format.html?
    should_add_status &&= options[:status].nil?
    should_add_status &&= !options.key?(:json) && !options.key?(:turbo_stream)

    options[:status] = :unprocessable_entity if should_add_status

    super(*args, **options, &block)
  end
end
