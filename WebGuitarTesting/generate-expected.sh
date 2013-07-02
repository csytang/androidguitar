testcase_dir="."

expected_dir=$testcase_dir"/expected"

# generate-expected.sh <testname> <websiteUrl>

testname=$1
website=$2

max_testcases=10



testcase_expected_dir=$expected_dir/$testname

generated_testcase_dir="$testcase_expected_dir/TC"

if [ ! -d $expected_dir ]; then
  echo "[INFO] generate-expected($testname): Creating EXPECTED directory: $expected_dir"
  mkdir $expected_dir
fi

if [ ! -d $testcase_expected_dir ]; then
  echo "[INFO] generate-expected($testname): Creating EXPECTED directory for this testcase"
  mkdir $testcase_expected_dir
fi


output_file_path=$testcase_expected_dir/$testname


# use clean log
export GUITAR_OPTS="-Dlog4j.configuration=log/guitar-clean.glc"

dist_dir="../dist/guitar"

width=3
depth=3

profile_args="-p firefoxV6"

ripper_args="--website-url $website -w $width -d $depth -g $output_file_path.GUI -b Firefox $profile_args"



# run ripper

echo "[INFO] - generate-expected($testname): Running ripper.."
bash $dist_dir/sel-ripper.sh $ripper_args 



# run gui 2 efg
gui_to_efg_args="-g $output_file_path.GUI -e $output_file_path.EFG"

echo "[INFO] - generate-expected($testname): Running GUI-to-EFG.."
bash $dist_dir/gui2efg.sh $gui_to_efg_args


# run testcase generator
tc_args="-e $output_file_path.EFG -m $max_testcases -d $generated_testcase_dir"

echo "[INFO] - generate-expected($testname): Running testcase generator.."
bash $dist_dir/tc-gen-sq.sh $tc_args


# run replayer

echo "[INFO] - generate-expected($testname): Running replayer.."

for testcase in `find $generated_testcase_dir -name "*.tst"| head -n$max_testcases`  
do
  # getting test name 
	test_name=`basename $testcase`
	test_name=${test_name%.*}

  replayer_args="--website-url $website -g $output_file_path.GUI -e $output_file_path.EFG -t $testcase -g $test_name.orc -d 1000"

	bash $dist_dir/sel-replayer.sh $replayer_args
	mv GUITAR-Default.STA $generated_testcase_dir/$testname.$test_name.STA
	

done
echo "[INFO] - generate-expected($testname): Completed generation."



