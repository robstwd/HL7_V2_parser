#
class HL7msg
	@@file = "/home/rob/scripts/Projects/HL7_parser/samples/order_test.hl7"
	
	attr_reader :contents
	
	def initialize
		@raw_input = IO.readlines(@@file)
		@segments = []
	end
	
	def class
		@raw_input.class
	end
	
	def num_segments
		#~ "Number of segments: #{@raw_input.length}"
		@raw_input.length
	end
	
	def parse_contents
		@raw_input.each do |segment|
			@segments << segment.split("|")
			#~ puts segment
		end
	end
	
	def show_parsed_contents
		@segments
	end
	
end

msg = HL7msg.new
#~ puts msg.contents
#~ puts msg.num_segments
g = msg.parse_contents
#~ puts g.inspect
puts msg.show_parsed_contents[1].inspect
puts msg.show_parsed_contents[1][3]
