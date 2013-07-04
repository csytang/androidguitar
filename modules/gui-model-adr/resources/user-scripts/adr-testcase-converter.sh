#!/bin/bash

# Setup sdk tools, environment, and convert testcases from MonkeyRecorder to .tst format

SCRIPT_DIR=`dirname $0`
AUT_CLASSPATH=.

AUT_DIRECTORY=$1
AUT_PACKAGE=$2
AUT_MAIN=$3
RESULT_DIR=$4
AUT_DISPLAY=$5
AUT=$AUT_PACKAGE.$AUT_MAIN
port=10737

args=""

# intial waiting time
# change this if your application need more time to start
intial_wait=3000

# delay time between two events during ripping 
RIPPER_DELAY=500

# the length of test suite
TC_LENGTH=2

# delay time between two events during replaying  
# this number is generally smaller than the $RIPPER_DELAY
REPLAYER_DELAY=1000


#------------------------
# Output artifacts 
#------------------------

# Directory to store all output of the workflow 
output_dir="./Demo"

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

OLD_PATH=$PATH

# this function set ups workspace
_envr_setup()
{
    # turn off posix mode
    set +o posix
    
    # Preparing output directories
    mkdir -p $output_dir
    mkdir -p $testcases_dir
    mkdir -p $states_dir
    mkdir -p $logs_dir
}

# this function downloads and installs android tools
_installAndroidSDK()
{
    echo "    We will try to install android 2.2 and sdk tools."
            
    echo -e "==> Download Android SDK"
    downloader=$(which wget)
    if [ $downloader ]; then
            wget http://dl.google.com/android/android-sdk_r22.0.1-linux.tgz
    else
            curl http://dl.google.com/android/android-sdk_r22.0.1-linux.tgz > android-sdk_r22.0.1-linux.tgz
    fi

    cp android-sdk_r22.0.1-linux.tgz $HOME
    rm android-sdk_r22.0.1-linux.tgz
    cd $HOME

    echo -e "==> Uncompress Android SDK"
    tar xvfz android-sdk_r22.0.1-linux.tgz
    
    echo -e "==> Exporting sdk paths"
    tools_path="$HOME/android-sdk-linux/tools:$HOME/android-sdk-linux/platform-tools"
    original_PATH=${PATH}
    export PATH=${PATH}:${tools_path}
    echo "y" | android update sdk -u -t 1,2,12
}

# this function checks if android 2.2 exists
_checkAndroid2.2()
{
    id=100
    if [[ `android list targets | grep "android-8"` =~ [0-9]+ ]]; then
        id=${BASH_REMATCH[0]}
    fi
    
    if [[ id -ne 100 ]]; then
        echo -e "==> Android 2.2 exists, if build fails after this, try manually installing build-tools and platform-tools."
    else
        echo -e "==>    Android 2.2 is not installed."
        _installAndroidSDK
    fi
}

# this function set ups android sdks and tools
_androidSDK_setup()
{
    # Ripping
    found=$(which android)
    if [ $found ]; then
        echo -e "==> Android SDK Exists. We will skip download and test if android 2.2 is installed."
        
        _checkAndroid2.2
    else
        echo -e "==> Android not found in the PATH."
    
        if [ -d $HOME/android-sdk-linux/ ]; then
            echo -e "==> Found android folder under HOME. We skip download and test if tools exist."
            echo -e "==> Exporting sdk paths"
            
            tools_path="$HOME/android-sdk-linux/tools:$HOME/android-sdk-linux/platform-tools"
            original_PATH=${PATH}
            export PATH=${PATH}:${tools_path}
            
             id=100
             if [[ `android list targets | grep "android-8"` =~ [0-9]+ ]]; then
                    id=${BASH_REMATCH[0]}
             fi
    
             if [[ id -ne 100 ]]; then
                    echo -e " Android 2.2 exists, if build fails after this, try manually installing build-tools and platform-tools."
             else
                echo -e "Android 2.2 doesn't exist. Try installing it along with build-tools and platform-tools manually."
                exit
             fi
        else
            _installAndroidSDK
        fi
    fi
}


# this function installs test source files
_install_AUT()
{
    apk_file=`find adr-aut/$AUT_DIRECTORY -name *.apk | sed -n '/no_fault/p'`
    
    # Install AUT
    echo "==> Install AUT: $apk_file"
    cont=true
    while $cont ;
    do
        while read line
        do
            found=$(echo $line | grep Success)
            if [ "$found" ]; then
                cont=false
            fi
        done < <( adb install $apk_file )
    
        if $cont ; then
            echo "    The emulator is booting."
            echo "    We will retry."
        fi
        sleep 10
    done
    echo -e "\n"
}

# this function set ups emulator
_emulator_setup()
{
    echo -e "==> Kill the emulator process if running.\n"
    pkill emulator-arm
    killall emulator-arm
    
    echo "==> Delete the AVD if its name is ADRGuitarTest."
    android delete avd -n ADRGuitarTest
    echo -e "\n"
    
    echo "==> Create an AVD. Its name will be ADRGuitarTest."
    echo | android create avd -n ADRGuitarTest -t $id -s WQVGA432
    
    # ADR-Server Building
    echo -e "==> Build ADR-Server"
    cd adr-aut
    rm -f adr-server.apk
    cd adr-server
    
    android update project --name adr-server --target android-8 --path .
    python rename.py AndroidManifest.xml $AUT_PACKAGE
    ant debug
    ../resign.sh ./bin/adr-server-debug.apk ../adr-server.apk
    cd ../../
    
    # AUT Building
    echo -e "==> Build AUT"
    cd adr-aut/$AUT_DIRECTORY
    
    rm build.xml
    android update project --target android-8 -p .
    cp -rf src src.orig
    if [ ! -f ./bin/no_fault/AUT-resigned.apk ] || [ ! -f ./bin/no_fault/coverage.em ]; then
        ant instrument
        ../resign.sh ./bin/*-instrumented.apk ./bin/AUT-resigned.apk
        mkdir -p ./bin/no_fault
        cp ./bin/AUT-resigned.apk ./bin/no_fault
        # Changes, added ./bin/ to cp
        cp ./bin/coverage.em ./bin/no_fault
        # End Changes
    fi
    # Changes
    echo -e "Current Dir:"
    pwd
    # End Changes
    while read line
    do
        filename=${line##*/}
        pathname=${line%/*}
        original_path=`find src -name $filename`
        if [ ! -f ./bin/$pathname/AUT-resigned.apk ] || [ ! -f ./bin/$pathname/coverage.em ]; then
            echo "==> Fault seeded source file: $line"
            cp $line $original_path
            ant instrument
            ../resign.sh ./bin/*-instrumented.apk ./bin/AUT-resigned.apk
            mkdir -p ./bin/$pathname
            cp ./bin/AUT-resigned.apk ./bin/$pathname
            # Change, added ./bin/ to cp
            pwd
            cp ./bin/coverage.em ./bin/$pathname
            # End Changes
        fi
     
    done < <( find $RESULT_DIR -name *.java )
    rm -rf src
    mv src.orig src
    rm -rf bin/*.apk
    cd ../../
    
    # Run an emulator process
    echo -e "==> Run the created emulator.\n"
    emulator -avd ADRGuitarTest -cpu-delay 0 -netfast $AUT_DISPLAY -no-snapshot-save &
}

# this function connects to emulator display
_install_adr-server()
{
    # Install ADR-Server
    echo "==> Install ADR-Server."
    cont=true
    while $cont ;
    do
        while read line
        do
            found=$(echo $line | grep Success)
            if [ "$found" ]; then
                cont=false
            fi
    #    done < <( adb install adr-server/adr-server.apk )
        done < <( adb install adr-aut/adr-server.apk )
    
        if $cont ; then
            echo "  The emulator is booting."
            echo "  We will retry."
            adb kill-server
            adb start-server
        fi
        sleep 10
    done
    echo -e "\n"
}

# Clean up (kill the emulator if running, delete the emulator image, reset path)
_cleanup()
{
 pkill emulator
 killall emulator
 android delete avd -n ADRGuitarTest
 export PATH=$OLD_PATH
}

#./adr-emu.sh $1 $2 $3 $4

main()
{
 _envr_setup
 _androidSDK_setup
 _emulator_setup
 _install_adr-server
 _install_AUT
 
 # This script converts the file format outputed from MonkeyRecorder to .tst format used by other Guitar scripts
 monkeyrunner adr-testcase-converter.py recorded_actions.txt

 _cleanup
}

main "$@"
