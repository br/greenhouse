root = File.expand_path('../../', __FILE__)
require "#{root}/greenhouse"
require 'rack/test'
require 'rspec'

RSpec.configure do |c|
  # Use color in STDOUT
  c.color = true
  c.include Rack::Test::Methods
  # Use color not only in STDOUT but also in pagers and files
  c.tty = true

  # Use the specified formatter
  c.formatter = :documentation # :progress, :html, :textmate
  #c.around(:each) do |example|
  #  VCR.use_cassette(example.metadata[:full_description], :serialize_with => :json) do
  #    example.run
  #  end if ENV['VCR'] == '1'
  #end
  c.after(:all) do
  end
end

