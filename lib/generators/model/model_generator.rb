# frozen_string_literal: true

# Custom model generator that automatically adds data_version column
# for business tables (RLS requirement)
#
# Usage: rails g model ModelName attr1:type attr2:type
#
# This generator wraps Rails' default model generator and:
# 1. Auto-adds data_version:string:default='0':limit=50 for business tables
# 2. Excludes system models (Administrator, Session, etc.)
#
class ModelGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  # Pass through all arguments to Rails model generator
  argument :attributes, type: :array, default: [], banner: "field[:type][:index] field[:type][:index]"

  class_option :skip_migration, type: :boolean, default: false
  class_option :skip_factory, type: :boolean, default: false
  class_option :skip_spec, type: :boolean, default: false

  # System models that should not have data_version
  EXCLUDED_MODELS = %w[
    Administrator
    Session
    AdminOplog
    ValidatorExecution
    ActiveStorageBlob
    ActiveStorageAttachment
    ActiveStorageVariantRecord
  ].freeze

  def generate_model
    # Check if this is a business table (not a system model)
    is_business_table = !EXCLUDED_MODELS.include?(class_name)
    
    # Auto-add data_version for business tables
    enhanced_attributes = attributes.dup
    if is_business_table
      # Check if data_version is already in attributes
      has_data_version = enhanced_attributes.any? { |attr| attr.to_s.start_with?('data_version') }
      
      unless has_data_version
        enhanced_attributes << 'data_version:string:default=\'0\':limit=50'
        say "  → Auto-adding data_version column (required for RLS)", :yellow
      end
    end

    # Build generator options
    generator_options = []
    generator_options << "--skip-migration" if options[:skip_migration]
    generator_options << "--skip-factory" if options[:skip_factory]
    generator_options << "--skip-spec" if options[:skip_spec]

    # Invoke Rails' default model generator
    Rails::Generators.invoke(
      "active_record:model",
      [name] + enhanced_attributes + generator_options,
      behavior: behavior
    )
  end
end
