testcase_dir="."

total_count=0
error_count=0
succ_count=0

for testfile in `find $testcase_dir -name '*Test.sh'`
do
  let total_count+=1
  
  bash $testfile
  status=$?
  
  if [ $status -eq 0 ]; then
    echo "$testfile passed!"
    let succ_count+=1
  else
    echo "$testfile failed!"
    let error_count+=1
  fi
  
done


if [ $total_count -eq $succ_count ]; then
  #all passed
  echo "Test suite passed!"
  exit 0
else
  #some failed
  echo "Test suite failed: $error_count of $total_count failed!"
  exit 1
fi
