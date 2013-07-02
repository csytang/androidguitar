#!/usr/bin/env ruby
# Written by Whitney Ford
# Written by Siti Mashitah Shamsul-Anuar
# Debugged by Uyen-Truc Nguyen

# to run: ruby menuCommand.rb -f [filter type] [values to filter by, separated by spaces] -g [name of graph] -s [sort type] -n [name of test case]
# filter type: act, cmp, cat, other (you can search by any keyword or regex)
# sort type: act, cmp, cat

	
	#require 'Qt4'
	require 'functions.rb'
	require 'xml2dot.rb'
	require 'xml2table.rb'

	length = ARGV.length
	i = 0
	arguments = Hash.new
	validated = false
	sort = "none" # sort option eg "component", "category", "action"
	filterHash = Hash.new # filter option eg filterHash["act"] = ["android.intent.VIEW", "android.intent.EDIT"]
	outputArray = Array.new # output option eg outputArray = [ ["graph","graph.html] , ["log", "log.html"] ]
	sessionName = nil
	masterlog = nil # specifies the target masterlog.txt
	graphFile = nil
	#app = Qt::Application.new(ARGV)

		#window =Qt::Widget.new()
		#window.resize (500, 300)

		#quits program
		#quit = Qt::PushButton.new('Quit', window)
		#quit.font = Qt::Font.new('Times', 18, Qt::Font::Bold)
		#quit.setGeometry(10, 40, 180, 40)
		#Qt::Object.connect(quit, SIGNAL('clicked()'), app, SLOT('quit()'))
		#window.show()
		#app.exec()




########### RUN main code HERE!!! ###########

	#length = ARGV.length

	if(length == 0) then 
		#call GUI
	else

	#parse command be and
		i = 0
		curClassification = "null" #eg: -s, -o, -f
		curAspect = "null" #eg: cmp, act, cat

          #error checking
		while(i < length) do
			if((ARGV[i] == "-s") || (ARGV[i] == "-f") || (ARGV[i] == "-g") || (ARGV[i] == "-m") || (ARGV[i] == "-n"))
				curClassification = ARGV[i]
			elsif(curClassification == "-s")
				if(sort != "none")
					puts "invalid input for -s"
					break
				elsif((ARGV[i] != "cmp") && (ARGV[i] != "act") && (ARGV[i] != "cat"))
					puts "invalid input for -s"
					break
				else
					sort = ARGV[i]
				end
			elsif(curClassification == "-f")
				if((ARGV[i] == "cmp") || (ARGV[i] == "act") || (ARGV[i] == "cat") || (ARGV[i] == "other"))
					curAspect = ARGV[i]
					filterHash[curAspect] = Array.new
				elsif((curAspect != "cmp") && (curAspect != "act") & (curAspect != "cat") && (curAspect != "other"))
					puts "Invalid input on -f"
					break
				else
					temp = filterHash[curAspect] # gets array of eg filterHash["act"]
					# adds to array eg filterHash["act"] = temp + ["android.intent.VIEW"]
					filterHash[curAspect] = temp + [ARGV[i]] 
				end
			elsif(curClassification == "-g")
				graphFile = ARGV[i]
			elsif(curClassification == "-m")
				masterlog = ARGV[i]
			elsif(curClassification == "-n")
				sessionName = ARGV[i]
			end # end if
			i = i+1	
		end # end while(i < length) do
		

          #make calls 
		puts "\nOUTPUT: "
		
		#source 

			if(masterlog == nil)
				puts "Please specify which masterlog."
			else
			#XML is generated/LOG is generated/ filtering & sorting is taken care of			
			if(filterHash.keys != nil)
				
				out = File.new("filtered_#{sessionName}.txt", "w+") # reset filtered.txt to an empty file
				copy = File.open(masterlog, "r").readlines()
				out.write(copy)	# make a copy of masterlog (write to out)
				out.close
				filterHash.keys.each{ |k|	# create regex
					regex = ""
					filterHash[k].each{ |toFilter|
						regex += "|" + toFilter 

					}
					regex[0] = ""
					puts "k: ", k
					puts "regex: ", regex
					Functions.filter(k, regex, sessionName)
				}
			end # if(filterHash.keys != nil)
			#end here 2.58 pm
			#add here 4.42 pm -- to run sort
			if(sort != "none")
				Functions.sort(sort, sessionName, masterlog)
			end

		# create xml file from masterlog, the sorted log, or the filtered log
		Functions.log2xml(sessionName, masterlog)

		# makes human readable event log (html table)
		Xml2table.makeTable("intents_#{sessionName}.xml", "table_#{sessionName}.html")
		
		# make the graph			
		if (graphFile != nil) 
			Xml2dot.graph("intents_#{sessionName}.xml", "blah")	# make dot file
		        #%x[dot -Goverlap=prism -Tpng -o blah.png blah.dot]	# call Graphviz tool
			%x[circo -Goverlap=prism -Tpng -o blah.png blah.dot]	# call Graphviz tool. changed format on Wed 3/28 10:37pm.
		        File.rename("blah.png", "#{graphFile}.png")
		        File.rename("blah.dot", "#{graphFile}.dot")
		end
		
                end #if(sessionName != nil)
		# used for debugging
		puts "\nFILTER: "
		filterHash.keys.each{ |k|
			puts k + ": "
			puts filterHash[k]
		}
		puts "\nSORT: ",sort
		
		
	end #if (length == 0)



	#ensures command line args are entered properly


#app = Qt::Application.new(ARGV)
#quitWidget = QuitWidget.new()
#quitWidget.show()
#app.exec()		
