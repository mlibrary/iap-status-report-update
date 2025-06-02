require "bundler/setup"
Bundler.require
require "yaml"
require "zip"
require "csv"
require "fileutils"
require "erb"

require_relative "lib/person"
require_relative "lib/response"
require_relative "lib/responses"
require_relative "lib/department"
require_relative "lib/directory"
require_relative "lib/report"

config = YAML.safe_load(ERB.new(File.read("config.yml")).result, aliases: true)

directory = Directory.new(config["directory"])
puts "Loaded the directory."

responses = Responses.new(config["qualtrics"])
puts "Loaded the responses."

report = Report.new(config: config["reports"], directory: directory, responses: responses)
puts "Writing the reports."

report.write
