class ModelsGenerator < Rails::Generators::Base
  desc "Generate multiple models at once using + separator"

  # Accept all arguments
  argument :first_arg, type: :string, banner: "ModelName1"
  argument :rest_args, type: :array, default: [], banner: "attr1 + ModelName2 attr2"

  class_option :skip_migration, type: :boolean, default: false, desc: "Skip migration file generation"
  class_option :skip_factory, type: :boolean, default: false, desc: "Skip factory file generation"
  class_option :skip_spec, type: :boolean, default: false, desc: "Skip spec file generation"

  def generate_models
    # Combine all arguments
    all_args = [first_arg] + rest_args

    # Split arguments by +
    model_groups = []
    current_group = []

    all_args.each do |arg|
      if arg == '+'
        model_groups << current_group unless current_group.empty?
        current_group = []
      else
        current_group << arg
      end
    end
    model_groups << current_group unless current_group.empty?

    if model_groups.empty?
      say "Error: No model names provided", :red
      say "Usage: rails g models ModelName1 attr1 + ModelName2 attr2", :yellow
      say "Example: rails g models Post title:string + Comment body:text", :blue
      return
    end

    # Check if we're destroying or generating
    is_destroying = behavior == :revoke
    action = is_destroying ? "Destroying" : "Generating"

    say "\n#{action} #{model_groups.size} model(s)...\n", :green

    model_groups.each_with_index do |group, index|
      next if group.empty?

      model_name = group[0]
      attributes = group[1..-1] || []

      # Auto-add data_version column for business tables (exclude system models)
      excluded_models = %w[Administrator Session AdminOplog ValidatorExecution]
      unless is_destroying || excluded_models.include?(model_name.classify)
        # Check if data_version is already in attributes
        has_data_version = attributes.any? { |attr| attr.start_with?('data_version') }
        unless has_data_version
          attributes << 'data_version:string:default=\'0\':limit=50'
          say "  → Auto-adding data_version column (required for RLS)", :yellow
        end
      end

      action_msg = is_destroying ? "Destroying" : "Generating"
      say "\n#{index + 1}. #{action_msg} model: #{model_name} #{attributes.join(' ')}", :cyan

      # Build generator options
      generator_options = []
      generator_options << "--skip-migration" if options[:skip_migration]
      generator_options << "--skip-factory" if options[:skip_factory]
      generator_options << "--skip-spec" if options[:skip_spec]

      # Invoke model generator with appropriate behavior
      Rails::Generators.invoke(
        "model",
        [model_name] + attributes + generator_options,
        behavior: behavior
      )
    end

    done_msg = is_destroying ? "Destroyed" : "Generated"
    say "\n✓ Done! #{done_msg} #{model_groups.size} model(s).", :green
  end
end
