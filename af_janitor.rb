#!/usr/bin/env ruby

# This script is for deleting artifact between specified dates

require 'JSON'
require 'net/http'
require 'optparse'
require 'date'

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: af_janitor.rb [options]"
  opts.on('-s', '--start sdate', 'Start Date') do |sdate|
    options[:sdate] = sdate
  end

  opts.on('-e', '--end edate', 'End Date') do |edate|
    options[:edate] = edate
  end

  opts.on('-r', '--repo repo', 'Repository Name') do |repo|
    options[:repo] = repo
  end

  opts.on('-h', '--help', 'Help') do
    puts opts
    exit
  end
end

begin
  optparse.parse!
  mandatory = [:sdate, :edate, :repo]
  missing = mandatory.select { |parm| options[parm].nil? }
  unless missing.empty?
    puts "missing options: #{missing.join(', ')}"
    puts optparse
    exit
  end
end

start_time = Date.strptime("#{options[:sdate]}", '%m/%d/%Y').strftime '%s000'
end_time = Date.strptime("#{options[:edate]}", '%m/%d/%Y').strftime '%s000'

uri = URI("http://<af_domain>/artifactory/api/search/creation?from=#{start_time}&to=#{end_time}&repos=#{options[:repo]}")
req = Net::HTTP::Get.new(uri)
req.basic_auth '<user>', '<password>'
res = Net::HTTP.start(uri.hostname, uri.port) {|http|
  http.request(req)
}

if res.code == 200
  artifact_list_json = res.body
  artifact_list = JSON.parse(artifact_list_json)['results']
  artifact_list.each do |result|
    location = result['uri']
    location.sub!('api/storage/', '')
    location.sub!('https', 'http')
    loc = URI("#{location}")
    request = Net::HTTP::Delete.new(loc)
    request.basic_auth '<user>', '<passwd>'
    response = Net::HTTP.start(loc.hostname, loc.port) {|http|
      http.request(request)
    }
  end
else
  fail res.body
end
