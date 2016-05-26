require 'spec_helper'
module RubyArcClient
  describe Job do
      it "is failed when status says so" do
        expect(Job.new(status: "failed").failed?).to eq(true)
        expect(Job.new(status: "executing").failed?).to eq(false)
      end

      it "is completed when status says so" do
        expect(Job.new(status: "complete").completed?).to eq(true)
        expect(Job.new(status: "failed").completed?).to eq(false)
      end

      it "is running" do
        expect(Job.new(status: "executing").running?).to eq(true)
        expect(Job.new(status: "complete").running?).to eq(false)
        expect(Job.new(status: "failed").running?).to eq(false)
      end
  end
end
