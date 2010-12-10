#

module HL7parser

	@parsed_content = []
		
	class Message
		
		require 'yaml'
		
		def initialize(file)
			@file = file
	  end
	  
		def parse_contents
		# METHOD: parse the delimited character strings of a HL7 message into a multi-dimensinal array, to allow positional searching
		
			# read lines of the file into an array, each line as a separate element
			@raw_input = IO.readlines(@file)	# ie @raw_input[1] = "BHS|^~\&|PMSX21|GX3261|QMLPTX|QML|200004120817||GX3261_00014373.ORM||2173" etc
			
			# create an array to read the segment names eg => ["MSH", "PID", "PV1", "ORC", "OBR", "OBX"]; refer method 'getvalue', used to find the segment index
			@segment_list   = []			# initialise the array
			@raw_input.each { |segment| @segment_list << segment[0..2] }		# the array collects just the first 3 characters of each segment
			
			# remove extraneous carriage returns & line feeds ("\r\n") at the end of each line
			@raw_input.collect! { |segment| segment.chomp}
			
			# parse each segment into the various elements, as separated by "|" (eg ["BTS|1", "FTS|1|2173"] => [["BTS", "1"], ["FTS", "1", "2173"]])
			# ie create a nested multidimensional array with each segment represented by the first dimension 
			# and the second dimension representing each field within the segment
			@raw_input.collect! { |x| x.split("|")}
			
			# then parse each element where multiples are present, as separated by "~" (eg "P00057804^^^^PN~4009887514^^^AUSHIC^MC~SMIAL001^^^^PI" => ["P00057804^^^^PN", "4009887514^^^AUSHIC^MC", "SMIAL001^^^^PI"])	
			@raw_input.each do |x|						# for each array element which is one segment of the HL7 message
				x.collect! do |y| 							# then for each field (second dimension element)
					if y.include?("~") then				# if the sub-element contains the multiplicity delimiter, then 
						y.split("~")								# split that subelement into further sub-sub-elements using the "~" to separate the values
					else                       		# if there is no multiple values then...
						y														# just return the value unchanged
					end	
				end	
			end
			
			# then parse each element into its subcomponents, separated by "^" (eg "SMITH^Alan^Ross^^Mr" => ["SMITH", "Alan", "Ross", "", "Mr"])
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
			
			# finalise the array with contents for later searching
			@parsed_content = @raw_input
			
		end	  # << end parse_contents method
	  
	  def getvalue(element)
	  # METHOD: returns the value of a given aspoect of teh message by virtue of its position
	  # allows returning the segment value in total eg getvalue("PID"), down to the atomic element eg getvalue("PID-5-2")
 	  
			# separate the single arguemnt passed into the various elements
			elements         = element.split("-")			# "PID-5-2" => ["PID", "5", "2"]
			segment          = elements[0]						# segment   => "PID"
			field            = elements[1]						# field		  => "5"  
			component        = elements[2]						# component => "2"
			subcomponent     = elements[3]						# subcomponent => nil (in the above example)
			subsubcomponent  = elements[4]						# subsubcomponent => nil (in the above example)

			# get segment position, using the segment array created above
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
			
			# iterate over each segment
			@parsed_content.each do |segment|
				seg = segment[0]																  # seg => "PID"
				
				#get yaml file details
				yamlfile  = "../hl7specification/#{seg}"
				details   = YAML.load_file(yamlfile)
				
			  puts ":: Segment: #{seg}"				                  # print the text eg ":: Segment: 4 PID"
				segment.each_with_index do |field, index|					# then for each field in the particular segment
					fld = "#{seg}-#{index}"									       	# fld => "PID-5"
					print "#{fld}: <<name>> => "						       	# on each line print "PID-5: <<name>> => "
					#~ name = details[fld]["name"]
					if field.class == String then												# if the field is a string...
						#~ puts "#{details[fld]["name"]} => #{field}"			# then just print the string with a label eg "PID-7: 19770621"
						puts field
					elsif field.class == Array then											# otherwise if the field is an array, ie there is lower level structure...
						#~ puts "#{fld}: #{details[fld]["name"]} => #{field.inspect}"		      # then print the structure viz => PID-5: ["SMITH", "Alan", "Ross", "", "Mr"]
						puts field.inspect	
					end  
				end	
				puts	
		  end
	  
	  end  # << end print_segments method
	  	  
	end  # << end Message class

end  # << end HL7parser module

		
        # initialise the variable holding the complete YAML file contents, as a hash
    #~ @detail       = @details[@station]                       # get just the detail pertaining to the station of interest
    #~ @url          = "#{@@baseurl}#{@detail["id"]}"           # construct the full internode URL, using the base and the looked up ID number for the particular station
    #~ @stationname  = @detail["title"]  
