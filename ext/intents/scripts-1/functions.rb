# Written by Siti Mashitah Shamsul-Anuar
# Written by Emily Berk
# Written by Elijah Yoon
# Debugged by Uyen-Truc Nguyen

# type : act, cat, flg, cmp
# filter : some keyword you want to filter by
#ex. type:cat filter:HOME  -> only show intents with HOME category

class Functions
	$filterBool = "false"
	$sortBool = "false"

	def self.filter(type, filter, graphFile)
	  $filterBool = "true"
	  masterString = ""
	  #opens file and gets all the lines
	 # lines = File.open("masterLog.txt", "r").readlines()
	  file = File.open("filtered_#{graphFile}.txt", "r")
	  lines = file.readlines()
	  file.close
	 # lines = File.open("filtered.txt", "r").readlines()
	  f = Regexp.new(filter) #regular expression representation of the filter
	  lines.each{ |line| #for each line, if its an intent, will add to masterString iff the type specified contains the filter given
	    tmp = line.split
	    case tmp[0]
	    when "INTENT:"
	      case type
	      when "act"
		if tmp[3] =~ f
		  masterString << line << "\n" # if the line matches the filter, keep it (we could add a negate option that would mean if it matches, then filter OUT)
		end
	      when "cat"
		if tmp[4] =~ f
		  masterString << line << "\n" # if the line matches the filter, keep it (we could add a negate option that would mean if it matches, then filter OUT)
		end
	      when "other"
		if line =~ f
		  masterString << line << "\n" # if the line matches the filter, keep it (we could add a negate option that would mean if it matches, then filter OUT)
		end
	      when "cmp"
		if tmp[8] =~ f
		  masterString << line << "\n" # if the line matches the filter, keep it (we could add a negate option that would mean if it matches, then filter OUT)
		end
	      end
	    when "APPLICATION"
	      #TODO add fuctionality for Application Events
	      case type
	      when "other"
		if line =~ f
		  masterString << line << "\n" # if the line matches the filter, keep it (we could add a negate option that would mean if it matches, then filter OUT)
		end
	     end
	    when "GUITAR:"
	      #TODO add fuctionality for Guitar Events
	      case type
	       when "other"
		if line =~ f
		  masterString << line << "\n" # if the line matches the filter, keep it (we could add a negate option that would mean if it matches, then filter OUT)
		end
	      end
	    end
	  }
	  out = File.new("filtered_#{graphFile}.txt", "w+")  
	  out.write(masterString)
	  out.close

	end

	#type : act, cat, flg, cmp
	def self.sort (type, graphFile, masterlog)
	  masterString = ""
	  $sortBool = "true"
	  lineArray = []
	  #opens file and gets all the lines
	  if($filterBool == "false")
	  	#lines = File.open("masterLog_#{graphFile}.txt", "r").readlines()	# removed on 2/26 7:59pm
		lines = File.open(masterlog, "r").readlines()				# added on 2/26 7:59pm
		puts "opens masterLog"
	  else
		lines = File.open("filtered_#{graphFile}.txt", "r").readlines()
		puts "opens filtered"
	  end

	  lines.each{ |line|
	    tmp = line.split
	    case tmp[0]
	    when "INTENT:"
	      #add all lines to array
	      lineArray = lineArray + [line]
	    when "APPLICATION"
	      #TODO add fuctionality for Application Events
	    when "GUITAR:"
	      #TODO add fuctionality for Guitar Events
	    end
	  }
	  #sort array based on custom comparison
	  case type
	  when "act"
	    #lineArray.sort {|x, y| x.split[3] <=> y.split[3] }
	    l = lineArray.sort {|x, y| x.split[4] <=> y.split[4] }
	  when "cat"
	    l = lineArray.sort {|x, y|  x.split[4] <=> y.split[4] }
	  when "flg"
	    l = lineArray.sort {|x, y|  x.split[7] <=> y.split[7] }
	  when "cmp"
	    l = lineArray.sort {|x, y|  x.split[8] <=> y.split[8] }
	  end
	  #insert sorted lines into master string
	  l.each{ |line|
		masterString << line << "\n"
	  }
	  out = File.new("sorted_#{graphFile}.txt", "w+")  # write sorted on sorted.txt
	  out.write(masterString) 
	  out.close
	  $filterBool = "false" # reset filterBool to false
	end



	# converts masterlog to xml file
	# TODO: add command line argument for masterLog file (specific to each test case)
	def self.log2xml(graphFile, masterlog)
	  intentTag = "intent"
	  appinfoTag = "application-event"
	  guitarTag = "guitar"
	  actionTag = "action"
	  categoryTag = "category"
	  cmpTag = "component"
	  timeTag = "time"
	  flgTag = "flag"
	  dataTag = "data"
	  datetimeTag = "date-time"

	  # 3 options for creating xml: 
	  # if sorting, use sorted log file; if filtering, use filtered log file; if neither, use the masterlog file
	  # the sorted log file is based on the filtered log file so the sorted log file takes precedence
	  if($sortBool == "true")
		f = File.open("sorted_#{graphFile}.txt", "r")
		lines = f.readlines()
		f.close
	  elsif($filterBool == "true")
		f = File.open("filtered_#{graphFile}.txt", "r")
		lines = f.readlines()
		f.close
	  else
		f = File.open(masterlog, "r")
	  	lines = f.readlines()
		f.close
	  end

	  masterString = "<Events>\n"
	  lines.each{ |line|
	    tmp = line.split

	    # debugging
	    #output = ""
	    #tmp.each {|e| output << " " << "#{e}"}
	    #puts output

	    case tmp[0]
	    when "INTENT:"
	      #TODO add data, bnds (bounds)
	      #added date/time tag
	       masterString << "<"+intentTag+">\n" 
	       masterString << "\t<"+datetimeTag+">" << tmp[1] << " " << tmp[2] << "</"+datetimeTag+">\n"
	       masterString << "\t<"+actionTag+">" << tmp[3] << "</"+actionTag+">\n"
	       masterString << "\t<"+categoryTag+">" << tmp[4] << "</"+categoryTag+">\n"
	       masterString << "\t<"+flgTag+">" << (tmp[7]=="-"? "-" : tmp[7].delete!("flg=")) << "</"+flgTag+">\n"
	       masterString << "\t<"+cmpTag+">" << tmp[8] + "</"+cmpTag+">\n"
	       masterString << "</"+intentTag+">\n"
	    when "APPLICATION"
	      masterString << "<"+appinfoTag+">\n" 
	      masterString << "\t<"+datetimeTag+">" << tmp[2] << " " << tmp[3] << "</"+datetimeTag+">\n"
	      #masterString << "\t<info>" << tmp[4]+(tmp[5]=="-"? "" : " "<< tmp[5])<<"</info>\n"

	      # added to get the entire info string (from tmp[5] to the rest of the array)
	      masterString << "\t<info>" << tmp[4]
	      if (tmp[5]=="-") then
		masterString << "-"
	      else
		for i in 5..(tmp.length-1)
		   masterString << " " << "#{tmp[i]}"
		end
	      end

	      masterString <<"</info>\n"
	      masterString << "</"+appinfoTag+">\n"
	    when "GUITAR:"
	      masterString << "<"+guitarTag+">\n" 
	      masterString << "\t<"+datetimeTag+">" << tmp[1] << " " << tmp[2] << "</"+datetimeTag+">\n"
	      #masterString << "\t<info>" << tmp[3] << " " << tmp[4] <<"</info>\n"

	      # added to get the entire info string (from tmp[5] to the rest of the array)
	      masterString << "\t<info>" << tmp[3]
	      if (tmp[4]=="-") then
		masterString << "-"
	      else
		for i in 4..(tmp.length-1)
		   masterString << " " << "#{tmp[i]}"
		end
	      end

	      masterString <<"</info>\n"
	      masterString << "</"+guitarTag+">\n"
	    end

	  }
	  masterString << "</Events>"
	  out = File.new("intents_#{graphFile}.xml", "w+")  
	  out.write(masterString)
	  out.close

	end
end 
