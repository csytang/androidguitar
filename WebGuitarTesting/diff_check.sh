diff $1 $2 &>/dev/null
status=$?

if [ $status -eq 0 ]; then
	echo "MATCH"
else
	echo "MISMATCH"
fi



