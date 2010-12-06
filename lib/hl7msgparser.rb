#
class HL7msgparser
	@@file = "/home/rob/scripts/Projects/HL7_parser/samples/order_test.hl7"
	
	attr_reader :raw_input
	
	def initialize
		# each row of the HL7 file (ie each segment) is collected in individual array elements
		@raw_input = IO.readlines(@@file)		# ie @raw_input[1] = "BHS|^~\&|PMSX21|GX3261|QMLPTX|QML|200004120817||GX3261_00014373.ORM||2173" etc
		@segments = []			
	end
	
	def class
		@raw_input.class
	end
	
	def num_segments
		#~ "Number of segments: #{@raw_input.length}"
		@raw_input.length
	end
	
	# deprecated as of 6 Dec 2010
	def parse_contents
		@raw_input.each do |segment|
			@segments << segment.split("|")
			#~ puts segment
		end
	end
	
	# deprecated as of 6 Dec 2010
	def show_parsed_contents
		@segments
	end
	
	def parse_contents2
		# I suspect this can be way more elegant, but laid out in this stepwise fashion as I figure out what is required/works
	
    # 1) remove extraneous carriage returns & line feeds ("\r\n") at the end of each line
    @raw_input.collect! { |segment| segment.chomp}
    
    # 2) remove extraneous double "\\"
    #@raw_input.collect! { |segment| segment.gsub(/\\/,"\\") } - <<doesn't quite work - finds the '\\' but doesn't replace with one \>>
	
		# 2) parse each segment into the various elements, as separated by "|" (eg ["BTS|1", "FTS|1|2173"] => [["BTS", "1"], ["FTS", "1", "2173"]])
		#    ie create a nested multidimensional array with each segment represented by the first dimension 
		#    and the second dimension representing each element within the segment
		@raw_input.collect! { |x| x.split("|")}
		
		# 3) then parse each element where multiples are present, as separated by "~" (eg "P00057804^^^^PN~4009887514^^^AUSHIC^MC~SMIAL001^^^^PI" => ["P00057804^^^^PN", "4009887514^^^AUSHIC^MC", "SMIAL001^^^^PI"])
		@raw_input.each do |x|					# for each array element which is one segment of the HL7 message
			x.collect! do |y| 						# then for each second dimension element
				if y.include?("~") then			# if the sub-element contains the multiplicity delimiter, then 
					y.split("~")							# split that subelement into further sub-sub-elements using the "~" to separate the values
				else                        # if there is no multiple values then...
					y													# just return the value unchanged
				end	
			end	
		end
		
		# 4) then parse each element into its subcomponents, separated by "^" (eg "SMITH^Alan^Ross^^Mr" => ["SMITH", "Alan", "Ross", "", "Mr"])
		#    this is required for second level sub-elements as well as third level sub-sub-elements
		@raw_input.each do |x|						# for each array element which is one segment of the HL7 message, further divided into sub-elements
			x.collect! do |y| 							# for each of those sub-elements
				if y.class == Array then			# if the sub-element is further divided into sub-sub-elements (and is therefore an array)....
					y.collect! do |z|						# for each of those sub-sub-elements
						if z.include?("^") then		# if the sub-sub-element contains the delimiter "^" then...
							z.split("^")						# further divide the value into its component parts
						else                      # otherwise if no subcomponent parts...
						  z												# just return the value unaltered
						end
					end
				elsif y.include?("^") then		# however if the sub-element is not an array and the values do contain "^"...
					y.split("^")								# further divide the value into its component parts
				else                		      # otherwise if no subcomponent parts...
				  y														# just return the value unaltered
				end  
			end	
		end
		
	end
		
	# ideally it would be nice to be able to use the normal HL7 conventions
	# ie puts msg(PID-5-2) for patient's given name
	# needs more work, but this is the general idea.....

	def getvalue(element)
		components  = element.split("-")			# "PID-5-2" => ["PID", "5", "2"]
		segment     = components[0]
		dimension1  = components[1]
		dimension2  = components[2]
		dimension3  = components[3]
		dimension4  = components[4]
		@raw_input[segment][dimension1][dimension2][dimension3][dimension4]
	end	
		
	
end


