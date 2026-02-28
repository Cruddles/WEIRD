# frozen_string_literal: true

require 'weird/logging'
require 'pragmatic_segmenter'

# main Weird code
module Weird
  # TO DO

  # # Helper to load JSON files with error handling
  def load_json(file, critical)
    if File.Exists(file)
      JSON.parse(File.read(file))
      status("File loaded: #{file}", 0, Status::Verbosity::VERBOSE)
    elsif critical
      status('Critical file not found: {file}', 0, 0, Status::ErrorLevel::FATAL)
      exit
    else
      status('File not found: ', file, false, Status::Verbosity::LIGHT)
    end
  rescue StandardError => e
    if critical
      std_err_writer("Unexpected error loading #{file}.", e, error_level: Status::ErrorLevel::FATAL)
      exit
    else
      std_err_writer("Unexpected error loading #{file}.", e, error_level: Status::ErrorLevel::SERIOUS)
    end
  end

  def rule_file_path(name)
    pre = 'rules/'
    ext = '.json' # low pri - efficiency?
    pre + name + ext
  end

  # TODO: FUTURE: load into an array for re-use between wikis. Tiny relative performance hit as is.
  def load_rule_file(name)
    pathname = rule_file_path(name)
    if File.file(pathname)
      rules = load_json(pathname)
      status("Rules file loaded #{pathname}: #{rules.size} rules", 0, Status::Verbosity::LIGHT)
      status(rules, 1, Status::Verbosity::VERBOSE)
      status("\n", -1, Status::Verbosity::VERBOSE)
    else
      std_err_writer("Expected rules file missing: #{pathname}", e, error_level: Status::ErrorLevel::SERIOUS)
    end
    rules
  end

  def write_default_config(config_filepath)
    $config = [ # rubocop:disable Style/GlobalVars
      {
        'log' => {
          'path' => 'logs/',
          'prefix' => 'WEIRD_',
          'ext' => '.log'
        },
        site_list: 'sites/Sites.json'
      }
    ]
    File.write(config_filepath, JSON.pretty_generate($config)) # rubocop:disable Style/GlobalVars
    status("Default parameters written:\n", 0, 0, Status::ErrorLevel::WARN)
    status($config, 1, Status::Verbosity::VERBOSE) # rubocop:disable Style/GlobalVars
    status('', -1)
  rescue StandardError => e
    std_err_writer("Couldn't write default config: #{config_filepath}", e, Status::ErrorLevel::SERIOUS)
  end

  def load_credentials(site_name)
    # Load creds
    credentials_filepath = $config['credentials_path'] + site_name + $config['credentials_suffix'] # rubocop:disable Style/GlobalVars
    status("credentials_filepath: #{credentials_filepath}", 0, Status::Verbosity::VERBOSE)
    if File.file(credentials_filepath)
      creds = load_json(credentials_filepath)
      if creds.nil
        status('Empty credentials file, skipping site.', 0, 0, Status::ErrorLevel::SERIOUS)
        return nil
      elsif creds['username'].nil || creds['password'].nil
        status("Credentials file #{credentials_filepath} doesn't have username and password, skipping site.", 0, 0, Status::ErrorLevel::SERIOUS)
        return nil
      end
      creds
    else
      status("No credentials file #{credentials_filepath}, skipping site.", 0, 0, Status::ErrorLevel::SERIOUS)
      nil
    end
  end

  # very safe load text file as array of strings
  def load_txt(pathfilename)
    if File.file(pathfilename)
      text_file = File.readlines($config['site_list'], chomp: true).reject(&:empty?) # rubocop:disable Style/GlobalVars
      if text_file.nil
        status("Text file #{pathfilename} unexpectedly empty.", 0, 0, Status::ErrorLevel::WARN)
      else
        status("Text file #{pathfilename} loaded: #{text_file.size} lines.", 0, Status::Verbosity::LIGHT)
      end
      text_file
    else
      status("No such text file #{pathfilename}.", 0, 0, Status::ErrorLevel::WARN)
      nil
    end
  rescue StandardError => e
    std_err_writer("Serious error loading #{pathfilename}.", e, Status::ErrorLevel::SERIOUS)
    nil
  end
end
