#!/bin/bash

# This is a sample script to demonstrate 
# GUITAR general workflow 
# The output can be found in Demo directory  

# Updated by Nick Ink for iPhone guitar project (summer 2013)
# Revised 12 June 2013

#------------------------
# Running in script dir 
SCRIPT_DIR=`pwd`

#------------------------
# iphone project name
iph_project=$1

if [ ! $iph_project ]; then
	echo "No Xcode iPhone project file specified."
	exit
fi

# application directory 
aut_dir=$SCRIPT_DIR/iph-aut/$iph_project

# application classpath 
aut_classpath=$aut_dir/bin

# num test cases to run
testcase_num=$4

if [ -z $testcase_num ]; then
	testcase_num=5
fi

# server port number
port=8081

# application main class
mainclass=$iph_project

#------------------------
# Sample command line arguments 
args=""
jvm_options=""

# configuration for the application
# you can specify widgets to ignore during ripping 
# and terminal widgets 
configuration="$aut_dir/guitar-config/configuration.xml"

# xcode startup and compile time.
xcode_build_time=$2
ios_simulator_wait_time=$3

if [ -z $xcode_build_time ]; then
	xcode_build_time=10
fi
if [ -z $ios_simulator_wait_time ]; then
	ios_simulator_wait_time=20
fi

# intial waiting time
# change this if your application need more time to start
initial_wait=100

# delay time between two events during ripping 
ripper_delay=100

# the length of test suite
tc_length=2

# delay time between two events during replaying  
# this number is generally smaller than the $ripper_delay
replayer_delay=1000

# delay time between two steps during replaying
replayer_so=10000

#------------------------
# iOS simulator
#------------------------

# Command to run iphonesim
iphonesim_path="../ios-sim/build/Release/ios-sim"
project_binary_path="$aut_dir/build/Debug-iphonesimulator/${iph_project}.app"
run_iphonesim="$iphonesim_path launch $project_binary_path --exit &> ios_simulator.out &"

build_dir="$aut_dir/build"

#------------------------
# Output artifacts 
#------------------------

# Directory to store all output of the workflow 
output_dir="$aut_dir/Demo"

# Directory to store screenshots
screenshots_dir="$output_dir/screenshots"

# GUI structure file
gui_file="$output_dir/Demo.GUI"

# EFG file 
efg_file="$output_dir/Demo.EFG"

# Log file for the ripper 
# You can examine this file to get the widget 
# signature to ignore during ripping 
log_file="$output_dir/Demo.log"

# Test case directory  
testcases_dir="$output_dir/testcases"

# GUI states directory  
states_dir="$output_dir/states"

# Replaying log directory 
logs_dir="$output_dir/logs"

# Iph Replayer/Code Coverage directory
replayer_dir="$output_dir/replayer"

#------------------------
# Main workflow 
#------------------------

echo "iPhone GUITAR automated workflow script"

# check for interfering processes with the server
num_interfering_processes=$(lsof -i :${port} | wc -l)

if [ "$num_interfering_processes" -gt "0" ]; then
	rogue_pid=$(tokens=($(lsof -i :${port} | tail -n 1)); echo ${tokens[1]})
	echo "A process on this host is interfering with the ripper."
	#read -p "Press ENTER to kill interfering process (pid $rogue_pid)..."
	echo "Killing process (pid $rogue_pid)."
	cmd_kill_interfering="kill -9 $rogue_pid"
	
	# kill everything running on the needed port
	echo $cmd_kill_interfering
	eval $cmd_kill_interfering
fi

if [ ! -d $aut_dir ]; then
	echo "Directory $aut_dir does not exist. Failing."
	exit
fi

if [ -d $build_dir ]; then
	echo
	#read -p "The project $iph_project has already been built. Press ENTER to clean the build..."
	echo "Cleaning project $iph_project."
	cur_path=$(pwd)
	cd $aut_dir
	xcodebuild clean > /dev/null
	cd $cur_path
	rm -rf $build_dir
fi

if [ -d $output_dir ]; then
	echo
	#read -p "Old test output exists for project $iph_project. Press ENTER to delete..."
	echo "Removing old test data for project $iph_project."
	rm -rf $output_dir
	rm $aut_dir/ios_simulator.out
	rm $aut_dir/iph_ripper.out
fi


# Build ios-sim first
echo
echo "Building iOS simulator."
cmd_build_simulator="xcodebuild -project iph-aut/ios-sim/ios-sim.xcodeproj -configuration \"Release\" -target \"ios-sim\" > /dev/null"
pwd
echo $cmd_build_simulator
eval $cmd_build_simulator

# Adding application arguments if needed 
if [ ! -z $args ] 
then 
	cmd="$cmd -a \"$args\"" 
fi
# echo $cmd
eval $cmd


# verify that the firewall is turned off before proceeding with ripping
fw=$(defaults read /Library/Preferences/com.apple.alf globalstate)
if [ $fw -eq 1 ]; then
	echo
	echo "FIREWALL ERROR"
	echo "The firewall enabled on this host will interfere with the GUITAR ripper process. Disable the firewall to continue."
	exit
fi


# Prepare output directories
mkdir -p $output_dir
mkdir -p $testcases_dir
mkdir -p $states_dir
mkdir -p $logs_dir
mkdir -p $screenshots_dir


# First start the ripper
echo
echo
echo "-- RIP PHASE BEGIN --"
echo
echo "Starting ripper server."
cmd_ripper="$SCRIPT_DIR/iph-ripper.sh -cp $aut_classpath -p $port -g  $gui_file -cf $configuration -d $ripper_delay -i $initial_wait -l $log_file &> ripper.out &"

# adding application arguments if needed 
if [ ! -z $args ] 
then 
	cmd_ripper="$cmd_ripper -a \"$args\"" 
fi

echo $cmd_ripper
eval $cmd_ripper


echo
cd $aut_dir
echo "Building iOS client application $iph_project."
pwd
cmd="xcodebuild -configuration \"Debug\" -target \"TestScriptRunner\" -sdk iphonesimulator6.1 &> iph_ripper.out &"
echo $cmd
eval $cmd

echo "Waiting $xcode_build_time seconds for Xcode to build."
sleep $xcode_build_time


# verify that the simulator is built and exists
if [ ! -f $iphonesim_path ]; then
	echo
	echo "SIMULATOR NOT FOUND ERROR"
	echo "iOS simulator not found. Failing."
	cmd_kill_ripper="kill -9 $(tokens=($(lsof -i :${port} | tail -n 1)); echo ${tokens[1]})"
	echo "Deactivating ripper."
	eval $cmd_kill_ripper
	exit
fi

# verify that the project is built and exists
if [ ! -d $project_binary_path ]; then
	echo
	echo "PROJECT BINARY NOT FOUND ERROR"
	echo "Project build binary ($project_binary_path) not found. Check that the Xcode build process functioned correctly."
	cmd_kill_ripper="kill -9 $(tokens=($(lsof -i :${port} | tail -n 1)); echo ${tokens[1]})"
	echo "Deactivating ripper."
	eval $cmd_kill_ripper
	exit
fi

# verify that there was no build error
num_errors=$(cat iph_ripper.out | grep 'FAILED' | wc -l)
if [ $num_errors -gt "0" ]; then
	echo
	echo "BUILD ERROR"
	echo "A build error occurred for project $iph_project. The simulator may have been run too recently."
	echo "Check the log file $(pwd)/iph_ripper.out to diagnose the problem."
	cmd_kill_ripper="kill -9 $(tokens=($(lsof -i :${port} | tail -n 1)); echo ${tokens[1]})"
	echo "Deactivating ripper."
	eval $cmd_kill_ripper
	exit
fi


sleep 1
echo
echo "Starting iOS simulator, please wait $ios_simulator_wait_time seconds."

echo $run_iphonesim
eval $run_iphonesim
sleep $ios_simulator_wait_time

echo
kill_iph_skd="ps aux | grep i[pP]hone | awk '{print \$2}' | xargs -n 1 -I {} kill -9 {} &> /dev/null"
echo "Cleaning up iOS simulator."
echo $kill_iph_skd
eval $kill_iph_skd

cmd_kill_ripper="kill -9 $(tokens=($(lsof -i :${port} | tail -n 1)); echo ${tokens[1]})"
echo "Deactivating ripper."
eval $cmd_kill_ripper


if [ ! -f $gui_file ]; then
	echo "GUI FILE NOT FOUND ERROR"
	echo "The ripper did not generate a .GUI file. Check the error logs to diagnose the problem."
	exit
fi

echo "-- RIP PHASE END --"

echo



# Converting GUI structure to EFG
echo "About to convert GUI structure file to Event Flow Graph (EFG) file" 
#read -p "Press ENTER to continue..."
cmd="$SCRIPT_DIR/gui2efg.sh -g $gui_file -e $efg_file"
echo $cmd
eval $cmd

echo
echo "GENERATE TEST CASES"

# Generating test cases
echo
echo "About to generate test cases to cover all possible $tc_length-way event interactions" 
#read -p "Press ENTER to continue..."
cmd="$SCRIPT_DIR/tc-gen-sq.sh -e $efg_file -l $tc_length -m 0 -d $testcases_dir"
echo $cmd
eval $cmd

# Replaying generated test cases
echo
echo
echo "-- REPLAY PHASE BEGIN --"
echo
echo "About to replay test case(s)" 

i=0 
for testcase in `find $testcases_dir -name "*.tst"| head -n$testcase_num`  
	do
		echo
		
		# check for interfering processes with the server
		num_interfering_processes=$(lsof -i :${port} | wc -l)
		
		if [ "$num_interfering_processes" -gt "0" ]; then
			rogue_pid=$(tokens=($(lsof -i :${port} | tail -n 1)); echo ${tokens[1]})
			echo "A process on this host is interfering with the replayer."
			#read -p "Press ENTER to kill interfering process (pid $rogue_pid)..."
			echo "Killing process (pid $rogue_pid)."
			cmd_kill_interfering="kill -9 $rogue_pid"
			
			# kill everything running on the needed port
			echo $cmd_kill_interfering
			eval $cmd_kill_interfering
		fi
		
		# getting test name 
		test_name=`basename $testcase`
		test_name=${test_name%.*}
		echo "Got test $test_name"
	   
	   	cmd_replayer="$SCRIPT_DIR/iph-replayer.sh -cp $aut_classpath -g $gui_file -e $efg_file -t $testcase -i $initial_wait -d $replayer_delay -so $replayer_so -l $logs_dir/$test_name.log -gs $states_dir/$test_name.sta -cf $SCRIPT_DIR/configuration.xml &> replayer.out &"
	   	
	   	# adding application arguments if needed 
	   	if [ ! -z $args ] 
	   	then 
	   		cmd_replayer="$cmd_replayer -a \"$args\" " 
	   	fi
	   	
		echo "Activating replayer and replaying test $test_name"
	   	#echo $cmd_replayer 
	   	eval $cmd_replayer
	   	
	   	# Build the iOS application
	   	#cmd_build_app="xcodebuild -configuration \"Debug\" -target \"TestScriptRunner\" -sdk iphonesimulator6.1 &> iph_replayer.out &"
	   	#echo $cmd_build_app
	   	#eval $cmd_build_app
	
		# Execute the iOS application.
		echo "Starting iOS simulator."
		#echo $run_iphonesim
		eval $run_iphonesim
		
		sleep $ios_simulator_wait_time
	
		#echo "Cleaning up iOS simulator."
		#echo $kill_iph_skd
		eval $kill_iph_skd
		
		
		sleep 1
		replayer_pid=$(tokens=($(lsof -i :${port} | tail -n 1)); echo ${tokens[1]})
		
		if [ ! -z "$replayer_pid" ]; then
			cmd_kill_replayer="kill -9 $replayer_pid"
			echo "Deactivating replayer."
			echo $cmd_kill_replayer
			eval $cmd_kill_ripper
		fi
		
		#fail_count=$(grep "FAILED" iph_replayer.out | wc -l)
		exception_count=$(grep "ERROR General Exception thrown" replayer.out | wc -l)
		terminated_count=$(grep "NORMALLY TERMINATED" replayer.out | wc -l)
		
		#if [ "$fail_count" -gt "0" ]; then
		#	echo "TEST CASE ERROR"
		#	echo "$test_name failed to build. Check error log for details."
		#fi
		if [ "$exception_count" -gt "0" ]; then
			echo "TEST CASE ERROR"
			echo "$test_name had a replayer exception. Check error log for details."
		fi
		
		if [ "$terminated_count" -eq "1" ]; then
			echo "Test $test_name terminated successfully."
		fi
		if [ "$terminated_count" -lt "1" ]; then
			echo "Test $test_name had unknown result (presumed failed)."
		fi
		
		# Move all the output files to the test directory
		
		#mkdir -p $replayer_dir/$test_name/gcov
		#mv iph_replayer.out $replayer_dir/$test_name/
		#mv errorLogFromLastBuild.txt $replayer_dir/$test_name/

		mkdir -p $replayer_dir/$test_name/
		mv replayer.out $replayer_dir/$test_name/
		
		#mv build/$iph_project.build/Debug-iphonesimulator/TestScriptRunner.build/Objects-normal/i386/*  $replayer_dir/$test_name/gcov/ 
		
		i=$((i+1))
done

echo
echo "-- REPLAY PHASE END --"

echo
echo
echo "For ripper details, check file: $(pwd)/ripper.out"
echo "For replayer details, check file: $(pwd)/Demo/replayer/[TESTCASE]/replayer.out"
#echo "For iphone std output, check file: $(pwd)/Demo/replayer/[TESTCASE]/errorLogFromLastBuild.txt"
#echo "For code coverage, check file: $(pwd)/Demo/replayer/[TESTCASE]/gcov/"
echo "Replace [TESTCASE] with the name of the desired testcase from the commands above. Testcases are named t_e*_e*, for example: t_e1060101468_e1473899700."
