# StimulusValidationPipeline - Centralized file scanning and caching for Stimulus validation
#
# This pipeline scans controller and view files once and caches the results,
# eliminating redundant file scanning across multiple test cases.
class StimulusValidationPipeline
  attr_reader :controller_data, :view_files, :partial_parent_map

  def initialize(cache_manager: nil)
    @controllers_dir = Rails.root.join('app/javascript/controllers')
    @views_dir = Rails.root.join('app/views')
    @cache_manager = cache_manager

    if @cache_manager
      # Use incremental scanning with cache
      controller_files = Dir.glob(@controllers_dir.join('*_controller.ts'))
      view_files_list = get_all_view_files
      all_files = controller_files + view_files_list

      result = @cache_manager.fetch_incremental(files_to_track: all_files) do |changed_files, cached_data|
        scan_with_cache(changed_files, cached_data, controller_files, view_files_list)
      end

      @controller_data = result[:data][:controller_data]
      @view_files = result[:data][:view_files]
      @partial_parent_map = result[:data][:partial_parent_map]
    else
      # Original full scan
      @controller_data = scan_controllers
      @view_files = scan_view_files
      @partial_parent_map = build_partial_parent_map
    end
  end

  # Get controllers from parent files (recursive)
  # Returns array of controller names that are in scope at the partial's render location
  def get_controllers_from_parents(partial_path)
    controllers = []

    parent_files = partial_parent_map[partial_path] || []
    parent_files.each do |parent_file|
      parent_content = File.read(Rails.root.join(parent_file))
      parent_doc = Nokogiri::HTML::DocumentFragment.parse(parent_content)

      # Find the render line for this partial
      render_line = find_render_line(parent_content, partial_path)

      # DEBUG OUTPUT
      if partial_path.include?('hotel_traveler_selector')
        puts "\n[DEBUG] Processing partial: #{partial_path}"
        puts "[DEBUG] Parent file: #{parent_file}"
        puts "[DEBUG] Render line: #{render_line}"
      end

      # Extract controllers from ALL HTML data-controller attributes in parent file
      # (not just top-level ones, since partials can be nested deep in the structure)
      parent_doc.css('[data-controller]').each do |element|
        element['data-controller'].split(/\s+/).each do |controller|
          controllers << controller.strip
        end
      end

      # Extract controllers from ERB syntax with scope checking
      controllers_with_scopes = find_controllers_with_scopes(parent_content)
      
      # DEBUG OUTPUT
      if partial_path.include?('hotel_traveler_selector')
        puts "[DEBUG] Controllers with scopes found: #{controllers_with_scopes.inspect}"
      end
      
      # Only include controllers whose scope includes the render line
      if render_line
        controllers_with_scopes.each do |controller_info|
          if render_line >= controller_info[:start_line] && render_line <= controller_info[:end_line]
            controllers << controller_info[:name]
            # DEBUG OUTPUT
            if partial_path.include?('hotel_traveler_selector')
              puts "[DEBUG] ✅ Controller '#{controller_info[:name]}' IN SCOPE (render at #{render_line}, scope: #{controller_info[:start_line]}-#{controller_info[:end_line]})"
            end
          else
            # DEBUG OUTPUT
            if partial_path.include?('hotel_traveler_selector')
              puts "[DEBUG] ❌ Controller '#{controller_info[:name]}' OUT OF SCOPE (render at #{render_line}, scope: #{controller_info[:start_line]}-#{controller_info[:end_line]})"
            end
          end
        end
      else
        # If we can't find render line, fall back to including all controllers (old behavior)
        controllers_with_scopes.each do |controller_info|
          controllers << controller_info[:name]
        end
        # DEBUG OUTPUT
        if partial_path.include?('hotel_traveler_selector')
          puts "[DEBUG] ⚠️  No render line found, using fallback"
        end
      end

      if parent_file.include?('_')
        controllers.concat(get_controllers_from_parents(parent_file))
      end
    end

    # DEBUG OUTPUT
    if partial_path.include?('hotel_traveler_selector')
      puts "[DEBUG] Final controllers list: #{controllers.uniq.inspect}\n"
    end

    controllers.uniq
  end

  # Find the line number where a partial is rendered
  def find_render_line(content, partial_path)
    # Extract partial name from path: app/views/shared/_hotel_traveler_selector_modal.html.erb -> hotel_traveler_selector_modal
    partial_name = File.basename(partial_path, '.html.erb').sub(/^_/, '')
    
    # Also extract the directory: app/views/shared/_xxx.html.erb -> shared
    partial_dir = File.dirname(partial_path).sub('app/views/', '')
    
    lines = content.split("\n")
    lines.each_with_index do |line, index|
      # Match: render 'shared/hotel_traveler_selector_modal' or render 'hotel_traveler_selector_modal'
      if line.match?(/render\s+(?:partial:\s*)?['"](?:#{partial_dir}\/)?#{partial_name}['"]/) ||
         line.match?(/render\s+(?:partial:\s*)?['"]#{partial_name}['"]/)
        return index + 1  # Line numbers are 1-indexed
      end
    end
    
    nil
  end

  # Find all controllers with their scope boundaries (start and end lines)
  def find_controllers_with_scopes(content)
    controllers = []
    lines = content.split("\n")
    
    lines.each_with_index do |line, index|
      line_num = index + 1
      
      # Check for Rails hash syntax: data: { controller: "..." }
      if line.include?('controller:') && line =~ /controller:\s*['"]([^'"]+)['"]/
        controller_names = $1.split(/\s+/)
        scope_end = find_scope_end_for_line(lines, index)
        
        controller_names.each do |name|
          controllers << {
            name: name.strip,
            start_line: line_num,
            end_line: scope_end
          }
        end
      end
      
      # Check for HTML data-controller attribute
      if line.include?('data-controller=') && line =~ /data-controller=['"]([^'"]+)['"]/
        controller_names = $1.split(/\s+/)
        scope_end = find_scope_end_for_line(lines, index)
        
        controller_names.each do |name|
          controllers << {
            name: name.strip,
            start_line: line_num,
            end_line: scope_end
          }
        end
      end
    end
    
    controllers
  end

  # Find scope end for a controller definition at given line index
  def find_scope_end_for_line(lines, start_index)
    start_line = lines[start_index]
    
    # Check if this is a Rails helper (form_with, link_to, etc.) with a block
    if start_line.include?('<%=') && (start_line.include?('form_with') || start_line.include?('link_to') || start_line.include?('do |'))
      return find_erb_block_end(lines, start_index)
    end
    
    # Check if this is a regular HTML tag
    if start_line =~ /<(\w+)/
      tag_name = $1
      return find_html_tag_end(lines, start_index, tag_name)
    end
    
    # Default: scope extends to end of file
    lines.length
  end

  # Find the end of an ERB block (matching <% end %>)
  def find_erb_block_end(lines, start_index)
    depth = 0
    block_started = false
    
    (start_index...lines.length).each do |i|
      line = lines[i]
      
      # Count 'do' blocks
      block_starts = line.scan(/\bdo(?:\s*\|[^|]*\||\s*(?:%>|$))/).length
      
      # Count if/unless/case/for/while blocks
      block_starts += 1 if line =~ /<%\s*(?:if|unless|case|for|while)\b/
      
      if block_starts > 0
        depth += block_starts
        block_started = true if i == start_index
      end
      
      # Count 'end' statements
      if line =~ /<%\s*end\s*%>/
        depth -= 1
        return i + 1 if depth == 0 && block_started
      end
    end
    
    # No matching end found
    lines.length
  end

  # Find the end of an HTML tag
  def find_html_tag_end(lines, start_index, tag_name)
    depth = 0
    tag_found = false
    
    (start_index...lines.length).each do |i|
      line = lines[i]
      
      # Count opening tags
      depth += line.scan(/<#{tag_name}(?:\s|>)/).length
      tag_found = true if depth > 0
      
      # Count closing tags
      closing_count = line.scan(/<\/#{tag_name}>/).length
      depth -= closing_count
      
      return i + 1 if depth == 0 && tag_found
    end
    
    # No matching closing tag found
    lines.length
  end

  private

  # Get all view files with filtering
  def get_all_view_files
    all_files = Dir.glob(@views_dir.join('**/*.html.erb'))

    if ENV['FULL_VIEW_DEBUG']
      all_files.reject { |file| file.include?('shared/demo.html.erb') }
    else
      all_files.reject do |file|
        file.include?('shared/demo.html.erb') ||
        file.include?('/admin/') ||
        file.include?('/kaminari/') ||
        file.include?('/shared/admin/') ||
        file.end_with?('/bookings/new.html.erb') ||
        file.end_with?('/train_bookings/new.html.erb') ||
        file.include?('shared/friendly_error.html.erb') ||
        file.include?('shared/missing_template_fallback.html.erb')
      end
    end
  end

  # Scan with cache: only rescan changed files and merge with cached data
  def scan_with_cache(changed_files, cached_data, controller_files, view_files_list)
    # Initialize from cache or empty
    controller_data = cached_data&.dig(:controller_data) || {}
    view_files = cached_data&.dig(:view_files) || []
    partial_parent_map = cached_data&.dig(:partial_parent_map) || {}

    # Determine which files changed
    changed_controller_files = changed_files & controller_files
    changed_view_files = changed_files & view_files_list

    # Rescan changed controllers
    unless changed_controller_files.empty?
      changed_controller_files.each do |file|
        controller_name = File.basename(file, '.ts').gsub('_controller', '').gsub('_', '-')
        controller_data[controller_name] = scan_single_controller(file)
      end
    end

    # Update view files list
    view_files = view_files_list

    # Rebuild partial parent map if any view files changed
    unless changed_view_files.empty?
      partial_parent_map = build_partial_parent_map_from_files(view_files)
    end

    {
      controller_data: controller_data,
      view_files: view_files,
      partial_parent_map: partial_parent_map
    }
  end

  # Scan a single controller file
  def scan_single_controller(file)
    controller_name = File.basename(file, '.ts').gsub('_controller', '').gsub('_', '-')

    # Use TypeScript AST parser to extract controller metadata
    parser_script = Rails.root.join('bin/parse_ts_controller.js')
    result_json = `node #{parser_script} #{file}`

    if $?.success?
      parsed_data = JSON.parse(result_json)

      {
        targets: parsed_data['targets'] || [],
        optional_targets: parsed_data['optionalTargets'] || [],
        outlets: parsed_data['outlets'] || [],
        values: parsed_data['values'] || [],
        values_with_defaults: parsed_data['valuesWithDefaults'] || [],
        values_with_dynamic_defaults: parsed_data['valuesWithDynamicDefaults'] || [],
        optional_values: parsed_data['optionalValues'] || [],
        methods: parsed_data['methods'] || [],
        querySelectors: parsed_data['querySelectors'] || [],
        anti_patterns: parsed_data['antiPatterns'] || [],
        targets_with_skip: parsed_data['targetsWithSkip'] || [],
        values_with_skip: parsed_data['valuesWithSkip'] || [],
        is_system_controller: parsed_data['isSystemController'] || false,
        file: file
      }
    else
      raise 'Parse ts controller failed'
    end
  end

  # Scan all TypeScript controllers and parse their metadata
  def scan_controllers
    data = {}

    Dir.glob(@controllers_dir.join('*_controller.ts')).each do |file|
      controller_name = File.basename(file, '.ts').gsub('_controller', '').gsub('_', '-')
      data[controller_name] = scan_single_controller(file)
    end

    data
  end

  # Scan all view files with filtering
  def scan_view_files
    all_files = Dir.glob(@views_dir.join('**/*.html.erb'))

    if ENV['FULL_VIEW_DEBUG']
      all_files.reject { |file| file.include?('shared/demo.html.erb') }
    else
      all_files.reject do |file|
        file.include?('shared/demo.html.erb') ||
        file.include?('/admin/') ||
        file.include?('/kaminari/') ||
        file.include?('/shared/admin/') ||
        file.end_with?('/bookings/new.html.erb') ||  # Only match /bookings/new.html.erb, not hotel_bookings or tour_group_bookings
        file.end_with?('/train_bookings/new.html.erb') ||  # Match exact path
        file.include?('shared/friendly_error.html.erb') ||
        file.include?('shared/missing_template_fallback.html.erb')
      end
    end
  end

  # Build a map of partial files to their parent files
  def build_partial_parent_map
    build_partial_parent_map_from_files(@view_files)
  end

  # Build partial parent map from a given list of view files
  def build_partial_parent_map_from_files(view_files)
    map = {}

    view_files.each do |view_file|
      content = File.read(view_file)
      relative_path = view_file.sub(Rails.root.to_s + '/', '')

      content.scan(/render\s+(?:partial:\s*)?['"]([^'"]+)['"]/) do |match|
        partial_name = match[0]

        if partial_name.include?('/')
          # shared/admin/header -> app/views/shared/admin/_header.html.erb
          partial_path = "app/views/#{partial_name.gsub(/([^\/]+)$/, '_\1')}.html.erb"
        else
          # header -> app/views/current_dir/_header.html.erb
          current_dir = File.dirname(relative_path)
          partial_path = "#{current_dir}/_#{partial_name}.html.erb"
        end

        map[partial_path] ||= []
        map[partial_path] << relative_path
      end
    end

    map
  end
end
