require 'hl7parser'

describe "HL7msg" do
	before :each do
      @msg = HL7msg.new
    end

	it "should exist" do
		@msg.should be_an_instance_of(HL7msg)
	end
end
