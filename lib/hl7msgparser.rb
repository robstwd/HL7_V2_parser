# much of the following would clearly be written much more elegantly than I have created. The 'step-wise' approach has been more for my own 
# process to just make it work and to understand what is happening

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
			
			# re-add an element for 'file field separator' ("|") for the segments FHS, BHS & MSH
			encodingchar = ""										# prepare to get the value of the encoding characters for later re-insertion into the array (ie "^~\&")	
			# iterate over each segment & insert the value "|" into the array, at position 1 if the segment is MSH, BHS or FHS
			@raw_input.each do |segment|				
				segment.insert(1,"|") if segment[0] =~ /(MSH|BHS|FHS)/
				encodingchar = segment[2] if segment[0] =~ /(MSH|BHS|FHS)/		# collect the value of the encoding characters
			end	
							
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
						
			# replace the 'encoding character' values ("^~\&")as they were removed in the above operations
			# almost works; ie returns "FHS-2: File Encoding Characters => ["^~\\&"]"
			# TODO: better result would be "FHS-2: File Encoding Characters => ^~\&"
			# iterate over each segment, replace the existing value with the encoding characters, determined earlier if the segment is MSH, BHS or FHS
			@raw_input.each { |segment| segment[2].replace([encodingchar]) if segment[0] =~ /(MSH|BHS|FHS)/ } 							
			
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
		# METHOD: after all of the HL7 content has been parsed, print the contents of each segment in a mor eeasily readible format
		# output for 1 segment looks like:
					#~ :: Segment: PID
					#~ PID-0: Segment => PID
					#~ PID-1: Set ID - PID => 1
					#~ PID-2: Patient ID => 
					#~ PID-3: Patient Identifier List => [["P00057804", "", "", "", "PN"], ["4009887514", "", "", "AUSHIC", "MC"], ["SMIAL001", "", "", "", "PI"]]
					#~ PID-4: Alternate Patient ID - PID => 
					#~ PID-5: Patient Name => ["SMITH", "Alan", "Ross", "", "Mr"]
					#~ PID-6: Mother’s Maiden Name => 
					#~ PID-7: Date/Time of Birth => 19770621
					#~ PID-8: Sex => M
					#~ PID-9: Patient Alias => 
					#~ PID-10: Race => 
					#~ PID-11: Patient Address => ["818 Beach Road", "", "BEECHMERE", "", "4510", "AU", "H"]

			# iterate over each segment
			@parsed_content.each do |segment|
				seg = segment[0]																  # eg => "PID"
				
				#get yaml file details
				yamlfile  = "../hl7specification/#{seg}"					# for each segment, find the appropriate yaml file (ie one for each segment)
				specs     = YAML.load_file(yamlfile)							# load the yaml file
				
			  puts ":: #{specs["Header"]["name"]} (#{seg})"			# print the text eg ":: Message Header Segment (MSH)"
			  
			  # then iterate over each field in the particular segment
				segment.each_with_index do |field, index|					# then for each field...
					if index > 0 then																# only if the index is 1 or more (ie the first value is not useful here)
						fld = "#{seg}-#{index}"									      # get the field id => "PID-5"
						print "#{fld}: "						       						# on each line print the particular field being queried eg "PID-5: "
						fldname = specs[fld]["name"]									# get the name of the field from the yaml file
						print "#{fldname} => "												# print the field name after the field eg "PID-5: Patient Name"
						if field.class == String then									# if the field class is a string...
							puts field																	# then just print (ie add) the value of the string eg "PID-7: Date/Time of Birth => 19770621"
						elsif field.class == Array then								# otherwise if the field is an array, ie there is lower level structure...
							puts field.inspect													# then print the structure eg "PID-5 Patient Name => ["SMITH", "Alan", "Ross", "", "Mr"]"
						end  # << end if field...
					end  # << end if index > 0  
				end	  # << end segment.each_with_index
				puts	
		  end	  # << end @parsed_content.each
	  
	  end  # << end print_segments method
	  	  
	end  # << end Message class

end  # << end HL7parser module
