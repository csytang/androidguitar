##

if [[ "$1" = "" || "$2" = "" ]]; then
	echo "Usage: ./runner.sh aut_main_class_name aut_classpath"
	echo "*Note* The aut_main_class_name should be the fully-qualified name of your main class (e.g. my.package.MainClass)."
else
	
	#Check the OS
if [ `uname -s | grep -i cygwin | wc -c` -gt 0 ]
then
    osname="windows"	
elif [ `uname -s` = "Linux" ]
then
    osname="linux"
else
    osname="mac"
fi
	recorder_classpath="SWTRecorder/bin:../../../dist/guitar/jars/log4j-1.2.15.jar:../../../dist/guitar/jars/guitar-lib/gui-model-core.jar:../../../dist/guitar/jars/guitar-lib/gui-model-swt.jar:../../../dist/guitar/jars/guitar-lib/gui-ripper-core.jar:../../../dist/guitar/jars/guitar-lib/gui-ripper-swt.jar:./SWTRecorder/lib/swt-${osname}.jar"
aut_main_class=$1	
aut_classpath=$2

	java_cmd="java -cp ${aut_classpath}:${recorder_classpath} recorder.RecorderControlPanel ${aut_main_class}";

	echo $java_cmd
	eval $java_cmd
fi

