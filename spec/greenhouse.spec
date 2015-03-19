require 'spec_helper'

describe Sinatra::App do
  include Rack::Test::Methods

  def app
    Sinatra::App
  end

  describe Sinatra::App do
    describe "POST /create/instances" do
      it "returns a list of repos and instances" do
        post "/create/instances"
        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)).to eq []
      end
    end
  end
end
