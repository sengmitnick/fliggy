# frozen_string_literal: true

require 'securerandom'

# Generator for creating new validators
#
# Usage:
#   rails generate validator book_hotel_room "预订酒店房间" "用户需要预订指定城市的酒店房间"
#
# This will create:
#   - app/validators/vXXX_book_hotel_room_validator.rb (with auto-generated UUID)
#
# Arguments:
#   validator_name: Snake case name (e.g., book_hotel_room)
#   title: Chinese title (e.g., "预订酒店房间")
#   description: Chinese description (e.g., "用户需要预订指定城市的酒店房间")
class ValidatorGenerator < Rails::Generators::Base
  source_root File.expand_path('templates', __dir__)
  
  argument :validator_name, type: :string, desc: "Validator name in snake_case (e.g., book_hotel_room)"
  argument :title, type: :string, desc: "Validator title in Chinese (e.g., 预订酒店房间)"
  argument :description, type: :string, desc: "Validator description in Chinese"
  
  def create_validator_file
    # Force UTF-8 encoding for all arguments (convert from ASCII-8BIT)
    @title = title.dup.force_encoding('UTF-8').encode('UTF-8', invalid: :replace, undef: :replace)
    @description = description.dup.force_encoding('UTF-8').encode('UTF-8', invalid: :replace, undef: :replace)
    
    # Find next validator number
    validator_number = next_validator_number
    
    # Determine target directory based on validator number
    target_dir = determine_target_directory(validator_number.to_i)
    
    # Generate UUID for task_id
    task_id = SecureRandom.uuid
    
    # Create validator file
    template_file = 'validator.rb.tt'
    output_file = "#{target_dir}/v#{validator_number}_#{validator_name}_validator.rb"
    
    @validator_number = validator_number
    @class_name = "V#{validator_number}#{validator_name.camelize}Validator".force_encoding('UTF-8')
    @validator_id = "v#{validator_number}_#{validator_name}_validator".force_encoding('UTF-8')
    @task_id = task_id.force_encoding('UTF-8')
    @title = @title
    @description = @description
    
    # Generate content from template
    template_content = File.read(File.expand_path('templates/validator.rb.tt', __dir__), encoding: 'UTF-8')
    
    # Replace ERB tags
    content = template_content.gsub('<%= @validator_number %>', validator_number)
                              .gsub('<%= @class_name %>', @class_name)
                              .gsub('<%= @validator_id %>', @validator_id)
                              .gsub('<%= @task_id %>', @task_id)
                              .gsub('<%= @title %>', @title)
                              .gsub('<%= @description %>', @description)
    
    # Write file with UTF-8 encoding
    create_file output_file, content, force: true
    
    say "✅ Created validator: #{output_file}", :green
    say "   - Validator ID: #{@validator_id}", :green
    say "   - Task ID (UUID): #{@task_id}", :green
    say "   - Class Name: #{@class_name}", :green
    say ""
    say "📝 Next steps:", :yellow
    say "   1. Implement the prepare method (define task parameters)", :yellow
    say "   2. Implement the verify method (add assertions)", :yellow
    say "   3. Implement the simulate method (AI agent logic)", :yellow
    say "   4. Run: rake validator:simulate to test", :yellow
  end
  
  private
  
  # Determine target directory based on validator number
  # v001-v050 → app/validators/v001_v050/
  # v051-v100 → app/validators/v051_v100/
  # v101-v150 → app/validators/v101_v150/
  # v151-v200 → app/validators/v151_v200/ (future)
  def determine_target_directory(number)
    case number
    when 1..50
      'app/validators/v001_v050'
    when 51..100
      'app/validators/v051_v100'
    when 101..150
      'app/validators/v101_v150'
    when 151..200
      'app/validators/v151_v200'
    else
      # For numbers > 200, calculate dynamically
      start_range = ((number - 1) / 50) * 50 + 1
      end_range = start_range + 49
      "app/validators/v#{start_range.to_s.rjust(3, '0')}_v#{end_range.to_s.rjust(3, '0')}"
    end
  end
  
  def next_validator_number
    # Find all existing validators in all subdirectories
    existing_validators = Dir.glob(Rails.root.join('app', 'validators', '**', 'v*_validator.rb'))
    
    if existing_validators.empty?
      return '001'
    end
    
    # Extract numbers and find max
    numbers = existing_validators.map do |file|
      File.basename(file).match(/v(\d+)_/)[1].to_i
    end
    
    max_number = numbers.max
    (max_number + 1).to_s.rjust(3, '0')
  end
end
