#
module HL7parser
	@parsed_content = []
		
	class Message
		
		def initialize(file)
			@file = file
	  end
	  
		def parse_contents
			@raw_input = IO.readlines(@file)
			@segment_list   = []
			@raw_input.each { |segment | @segment_list << segment[0..2] }
			@raw_input.collect! { |segment| segment.chomp}
			@raw_input.collect! { |x| x.split("|")}
			@raw_input.each do |x|						# for each array element which is one segment of the HL7 message
				x.collect! do |y| 							# then for each second dimension element
					if y.include?("~") then				# if the sub-element contains the multiplicity delimiter, then 
						y.split("~")								# split that subelement into further sub-sub-elements using the "~" to separate the values
					else                       		# if there is no multiple values then...
						y														# just return the value unchanged
					end	
				end	
			end
			
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
			
			@parsed_content = @raw_input
			
		end	  # << end parse_contents method
	  
	  def getvalue(element)
			elements         = element.split("-")			# "PID-5-2" => ["PID", "5", "2"]
			segment          = elements[0]
			field            = elements[1]
			component        = elements[2]
			subcomponent     = elements[3]
			subsubcomponent  = elements[4]

			# get segment position
			segment_position = @segment_list.find_index(segment)
			
			# get field position
			field_position = field.to_i if field != nil
			
			# get component position
			component_position = component.to_i - 1 if component != nil
			
			# construct value get statement
			if (segment_position != nil) and (field_position == nil) and (component_position == nil) then
				@parsed_content[segment_position]
			elsif (segment_position != nil) and (field_position != nil) and (component_position == nil) then
				@parsed_content[segment_position][field_position]
			elsif (segment_position != nil) and (field_position != nil) and (component_position != nil) then
				@parsed_content[segment_position][field_position][component_position]
			end
			
	  end	 # << end getvalue method
	  
	  def print_segments
	  
	  end  # << end print_segments method
	  	  
	end  # << end Message class

end  # << end HL7parser module


