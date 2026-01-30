# frozen_string_literal: true

require 'digest'
require 'json'

# Intelligent cache manager for Stimulus validation tests
# Implements incremental scanning: only re-scans files that have changed
class StimulusCacheManager
  CACHE_DIR = Rails.root.join('tmp/test_cache')
  CACHE_VERSION = '1.0.0' # Bump this to invalidate all caches

  def initialize(cache_key)
    @cache_key = cache_key
    @cache_file = CACHE_DIR.join("#{cache_key}.json")
    ensure_cache_dir_exists
  end

  # Get cached data if valid, otherwise yield to rebuild
  def fetch(files_to_track: [], &block)
    if cache_valid?(files_to_track)
      load_cache
    else
      data = block.call
      save_cache(data, files_to_track)
      data
    end
  end

  # Fetch with incremental scanning support
  # Returns: { data: <cached_or_new_data>, changed_files: [<list of changed files>] }
  def fetch_incremental(files_to_track: [], &block)
    cached_data = load_cache
    changed_files = detect_changed_files(files_to_track, cached_data)

    if changed_files.empty? && cached_data
      # All files unchanged, use cache
      { data: cached_data[:data], changed_files: [] }
    else
      # Some files changed, yield for incremental rebuild
      # Pass cached[:data] to the block, not the whole cache object
      new_data = block.call(changed_files, cached_data&.dig(:data))
      save_cache(new_data, files_to_track)
      { data: new_data, changed_files: changed_files }
    end
  end

  # Clear cache for this key
  def clear
    @cache_file.delete if @cache_file.exist?
  end

  # Clear all test caches
  def self.clear_all
    FileUtils.rm_rf(CACHE_DIR) if CACHE_DIR.exist?
  end

  private

  def ensure_cache_dir_exists
    CACHE_DIR.mkpath unless CACHE_DIR.exist?
  end

  def cache_valid?(files_to_track)
    return false unless @cache_file.exist?

    cached_data = load_cache
    return false unless cached_data
    return false unless cached_data[:version] == CACHE_VERSION

    # Check if all tracked files have same mtime
    files_to_track.all? do |file|
      next false unless File.exist?(file)
      cached_mtime = cached_data[:file_mtimes][file]
      cached_mtime && cached_mtime == File.mtime(file).to_i
    end
  end

  def detect_changed_files(files_to_track, cached_data)
    return files_to_track if cached_data.nil?
    return files_to_track if cached_data[:version] != CACHE_VERSION

    changed = []
    files_to_track.each do |file|
      next unless File.exist?(file)
      cached_mtime = cached_data[:file_mtimes]&.[](file.to_s)
      current_mtime = File.mtime(file).to_i

      if cached_mtime.nil? || cached_mtime != current_mtime
        changed << file
      end
    end

    changed
  end

  def load_cache
    return nil unless @cache_file.exist?

    begin
      # Don't symbolize keys for file paths - they should remain strings
      data = JSON.parse(@cache_file.read)
      # Convert top-level keys to symbols manually
      # Also convert data hash keys to symbols for consistent access
      {
        version: data['version'],
        cached_at: data['cached_at'],
        file_mtimes: data['file_mtimes'], # Keep file paths as strings
        data: data['data'] ? {
          controller_data: symbolize_controller_data(data['data']['controller_data']),
          view_files: data['data']['view_files'],
          partial_parent_map: data['data']['partial_parent_map']
        } : nil
      }
    rescue JSON::ParserError, Errno::ENOENT
      nil
    end
  end

  # Convert controller_data nested hash keys to symbols
  def symbolize_controller_data(controller_data)
    return nil if controller_data.nil?
    
    result = {}
    controller_data.each do |controller_name, controller_info|
      result[controller_name] = {
        targets: controller_info['targets'],
        optional_targets: controller_info['optional_targets'],
        outlets: controller_info['outlets'],
        values: controller_info['values'],
        values_with_defaults: controller_info['values_with_defaults'],
        values_with_dynamic_defaults: controller_info['values_with_dynamic_defaults'],
        optional_values: controller_info['optional_values'],
        methods: controller_info['methods'],
        querySelectors: controller_info['querySelectors'],
        anti_patterns: controller_info['anti_patterns'],
        targets_with_skip: controller_info['targets_with_skip'],
        values_with_skip: controller_info['values_with_skip'],
        is_system_controller: controller_info['is_system_controller'],
        file: controller_info['file']
      }
    end
    result
  end

  def save_cache(data, files_to_track)
    # Build file mtime map with string keys
    file_mtimes = {}
    files_to_track.each do |file|
      file_mtimes[file.to_s] = File.mtime(file).to_i if File.exist?(file)
    end

    cache_data = {
      version: CACHE_VERSION,
      cached_at: Time.now.to_i,
      file_mtimes: file_mtimes,
      data: data
    }

    @cache_file.write(JSON.pretty_generate(cache_data))
  end
end
