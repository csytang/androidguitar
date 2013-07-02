#Manual:
#download virtual box at this link:
# https://www.virtualbox.org/wiki/Downloads
#download Ubuntu 12.04 LTS for 32-bit machine at this link:

# http://www.ubuntu.com/download/desktop

#Download Android sdk (SDK tools only) for Linux 32 and 64-bit machine from the web using this link:

 #http://developer.android.com/sdk/index.html

#extract the downloaded android sdk zip file in the home directory.
#to install android:

 #cd android-sdk-linux/tools

#./android sdk

#In the window that pops-up select Android version 2.2. Make sure no other versions of Android are #selected. The platform tools are automatically selected. Install the selected packages.
#in the next window that appears, select all the packages on the left and select accept license and install

#Once the download process is complete, close the SDK Manager Log and Android SDK Manager windows.
#To set path environment for android sdk:
#from the terminal open the bashrc file for edit:

 #gedit ~/.bashrc &

# pwd 

#copy the resulting path
#In the bashrc file, below the line « [ -z "$PS1" ] && return », enter the following command and paste the path in place of <sdk path>:

# export PATH=${PATH}:<sdk path>

#in terminal:

# cd ..

 #cd platform-tools

 #pwd 

#copy the resulting path
#append the new path to the export command in the bashrc file in place of <abd path> and save

# export PATH=${PATH}:<sdk path>:<abd path>

 

#cd

 
#Create a directory for the GUITAR sourcecode and within this directory checkout the project to a folder called guitar:

# mkdir androidintents-code

# cd androidintents-code

#install subversion:

# sudo apt-get install subversion

#Checkout the project in the terminal:

# svn checkout svn://svn.code.sf.net/p/guitar/code/trunk guitar

#cd guitar/modules/gui-model-adr/resources/user-scripts

#sh ./runscript.sh 
 
#Script:
cd
#Install Oracle Java 7 in Ubuntu via PPA:

 sudo add-apt-repository ppa:webupd8team/java

 sudo apt-get update

 sudo apt-get install oracle-java7-installer

#To install ruby:

 sudo apt-get install ruby

#to be able to run xvfb commands:

 sudo apt-get install xvfb

#To run the ant command you must be inside the guitar project directory

cd androidintents-code/guitar

#to install ant:

 sudo apt-get install ant

#To compile and package all tools related to the Android platform:

 ant adr.dist

#Copy the Intents Testcase Generator into guitar/dist/guitar

 cp -r modules/testcase-generator-intents dist/guitar/

#Change to package top directory after building, and make scripts executable

 cd dist/guitar

 chmod +x `find . -name '*.sh'`

 

bash RunIntentTestCases-try.sh HelloAUT com.aut HelloAUTActivity result

 

cd testcase-generator-intents

 sh ./IntentFinder-workflow.sh ..adr-aut/HelloAUT HellAUT

 

