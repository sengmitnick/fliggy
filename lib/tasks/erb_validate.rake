# frozen_string_literal: true

namespace :erb do
  desc 'Validate all ERB files HTML structure'
  task validate: :environment do
    puts '🔍 Running ERB HTML validation...'
    result = system('ruby bin/validate_erb_html')
    exit(1) unless result
  end

  desc 'Validate a single ERB file HTML structure'
  task :validate_file, [:file_path] => :environment do |_t, args|
    if args[:file_path].nil?
      puts '❌ Please provide a file path: rake erb:validate_file[app/views/home/index.html.erb]'
      exit(1)
    end

    puts "🔍 Validating #{args[:file_path]}..."
    result = system("ruby bin/validate_erb_html #{args[:file_path]}")
    exit(1) unless result
  end
end
