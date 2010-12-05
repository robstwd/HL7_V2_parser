require 'hl7msgparser'

describe "HL7msgparser" do
	before :each do
		@msg = HL7msgparser.new #("../samples/order_test.hl7")
	end

	it "should exist as a class" do
		@msg.should be_an_instance_of(HL7msgparser)
	end
	
	it "should read the contents of a HL7 file into an array" do
		@msg.class.should == Array
	end
	
	it "should output the correct number of segments (15 in this case)" do
		@msg.num_segments.should == 15
	end
	
	#~ it "should output the contents as a string" do 
		#~ @msg.contents.should be_an_instance_of(String)
	#~ end
	
end
