ENV['RACK_ENV'] = 'test'
require_relative '../../greenhouse'
require_relative '../spec_helper'
describe "Greenhouse" do
  def app
    Sinatra::Application
  end
  describe "POST /cleanup/instances" do
    it "returns an array of instances to clean up" do
      post '/cleanup/instances'
      expect(last_response).to be_ok
      expect(JSON.parse(last_response.body)).to include "terminated"
    end
  end
end
