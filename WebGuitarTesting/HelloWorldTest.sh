#Usage:
# HelloWorldTest.sh [isolate]
# NOTE: Isolate argument is optional and will default to true

# Prepare arguments for the testcase template script

testcase_template="./Testcase-Template.sh"
generate_script="./generate-expected.sh"
clean_up_script="./clean-up.sh"


testname="HelloWorldTest"
website="https://googledrive.com/host/0B6TP-LuwGMgZbERwOXF5ZTNzWW8/helloworld.html"
#DEFAULT VALUE FOR ISOLATE
isolate="true"


if [ ! -z "$1" ]; then

  if [ "$1" = "--generate" ]; then
    echo "[INFO] - $testname: Generating expected output.."
    bash $generate_script $testname $website
    bash $clean_up_script
    exit 0
  fi




  echo "[INFO] - $testname: isolate argument detected. Assigned to: $1"
  isolate=$1
fi


#execute testcase-template
bash $testcase_template $isolate $testname $website
status=$?
bash $clean_up_script
exit $status


