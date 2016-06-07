require 'spec_helper'

module RubyArcClient

  describe ApiError do

    it "should assign values from the exception response" do
      input = {"id":"99b49c7f-6a0d-4ad4-9aed-a3c2c1f5fb18","status":"Unauthorized","code":401,"title":"Not Authorized.","detail":"Authorization: Identity status invalid. Invalid is not 'Confirmed'","source":{"pointer":"(GET) /api/v1/agents","parameter":"map[]"}}
      err = ApiError.new(input)
      expect(err.json_data).to eq(input)
      expect(err.id).to eq("99b49c7f-6a0d-4ad4-9aed-a3c2c1f5fb18")
      expect(err.status).to eq("Unauthorized")
      expect(err.code).to eq(401)
      expect(err.title).to eq("Not Authorized.")
      expect(err.detail).to eq("Authorization: Identity status invalid. Invalid is not 'Confirmed'")
      expect(err.source).to eq("(GET) /api/v1/agents - map[]")
      expect(err.to_s).to eq("Not Authorized. Authorization: Identity status invalid. Invalid is not 'Confirmed'")
    end

  end

end