#!/bin/bash

# This script verifies, after running the HelloWorld test application,
# that the output files are standard and correct for the summer 2013
# version of iPhoneGUITAR

# Written by Nicholas Ink, CMSC435, summer 2013 for iPhoneGUITAR


echo "Nick's HelloWorld test script"
echo "iPhoneGUITAR -- CMSC435, Summer 2013"
echo


# error color definitions
SET_CONSOLE_PASSED='printf "\033[32m"'
SET_CONSOLE_ERROR='printf "\033[1m\033[31m"'
SET_CONSOLE_NORMAL='printf "\033[0m"'

# Begin by verifying that the GUI file exists
gui_file="./iph-aut/HelloWorld/Demo/Demo.GUI"
canonical_gui_file_md5="b53bb32b7fb25568c5ee2f4c0a9f6401"

if [ ! -f $gui_file ]; then
	eval $SET_CONSOLE_ERROR
	echo "Demo.GUI file not found. The ripper did not rip the application."
	eval $SET_CONSOLE_NORMAL
	exit
fi

actual_gui_file_md5="$(md5 -q $gui_file)"

if [ "$canonical_gui_file_md5" == "$actual_gui_file_md5" ]; then
	eval $SET_CONSOLE_PASSED
	echo "GUI file matched specifications. Ripper appears OK."
	eval $SET_CONSOLE_NORMAL
else
	eval $SET_CONSOLE_ERROR
	echo "GUI file has been mutated. The ripper may be faulty. Failing."
	eval $SET_CONSOLE_NORMAL
	exit
fi


# next check the EFG file
efg_file="./iph-aut/HelloWorld/Demo/Demo.EFG"
canonical_efg_file_md5="c27972b3a7a342287a2ab7a750d0145c"

if [ ! -f $efg_file ]; then
	eval $SET_CONSOLE_ERROR
	echo "Demo.EFG file not found. The EFG converter script is not running."
	eval $SET_CONSOLE_NORMAL
	exit
fi

actual_efg_file_md5="$(md5 -q $efg_file)"

if [ "$canonical_efg_file_md5" == "$actual_efg_file_md5" ]; then
	eval $SET_CONSOLE_PASSED
	echo "EFG file matched specifications. EFG converter script appears OK."
	eval $SET_CONSOLE_NORMAL
else
	eval $SET_CONSOLE_ERROR
	echo "EFG file has been mutated. The EFG converter script may have a flaw. Failing."
	eval $SET_CONSOLE_NORMAL
	exit
fi


echo


test_cases=( "t_e921760096_e921760158" "t_e921760096_e921760096" "t_e921760096_e921760282" "t_e921760096_e921760344" "t_e921760096_e921760406" )

test_case_checksums=( "e65937a5b94c7c42a2a82a35b158a683" "e8c5a26df6f5248e61a1b10cd7e66fbe" "6e7445ab3dcf6349cbbdb309680c7f2e" "e758fd1e29bbd4c8a01a9a274ff8bcdb" "6960d344ceb95a5c738ac3cc4acbea37" )

i=0
for test_case in "${test_cases[@]}"
do
	test_case_file="./iph-aut/HelloWorld/Demo/replayer/$test_case/replayer.out"
	canonical_test_case_file_md5=${test_case_checksums[$i]}
	
	if [ ! -f $efg_file ]; then
		eval $SET_CONSOLE_ERROR
		echo "Replayer files for test case $test_case not found. Cannot evaluate this case."
		eval $SET_CONSOLE_NORMAL
	else
		actual_test_case_md5="$(head -n 88 $test_case_file | tail -n 85 | grep -vE 'Step Timer' | md5)"
		if [ "$canonical_test_case_file_md5" == "$actual_test_case_md5" ]; then
			eval $SET_CONSOLE_PASSED
			echo "Test case results for test case $test_case appear OK."
			eval $SET_CONSOLE_NORMAL
		else
			eval $SET_CONSOLE_ERROR
			echo "Test case results for test case $test_case have been mutated. The replayer may have a flaw. Failing."
			eval $SET_CONSOLE_NORMAL
		fi
	fi
	
	i=$((i+1))
done
