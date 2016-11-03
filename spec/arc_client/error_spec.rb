require 'spec_helper'

module ArcClient

  describe ApiError do

    it "should assign values from the exception response" do
      input = '{"id":"83e940c4-7199-407f-8985-3cae72237ef1","status":"Unauthorized","code":401,"title":"Not authorized.","detail":"Authorization: Identity status invalid. Invalid is not Confirmed","source":{"pointer":"(GET) /api/v1/agents?q=\u0026page=0\u0026per_page=0\u0026facts=","parameter":"map[]"}}'
      err = ApiError.new(input)
      expect(err.json_data).to eq(input)
      expect(err.id).to eq("83e940c4-7199-407f-8985-3cae72237ef1")
      expect(err.status).to eq("Unauthorized")
      expect(err.code).to eq(401)
      expect(err.title).to eq("Not authorized.")
      expect(err.detail).to eq("Authorization: Identity status invalid. Invalid is not Confirmed")
      expect(err.source).to eq( "(GET) /api/v1/agents?q=\u0026page=0\u0026per_page=0\u0026facts= - map[]")
      expect(err.to_s).to eq("Not authorized. Authorization: Identity status invalid. Invalid is not Confirmed")
    end

  end

end