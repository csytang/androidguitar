#checks out from our svn
#svn checkout svn://svn.code.sf.net/p/androidintents/code/trunk androidintents-code
#cd androidintents-code


#moves parser.rb
cp scripts/parser.rb parser.rb

#[[ -f test.txt ]] && echo ls || sed -i 's/emulator -avd ADRGuitarTest -cpu-delay 0 -netfast $5 -no-snapshot-save &/xvfb-run -a &/g' guitar/modules/gui-model-adr/resources/user-scripts/adr-sample-workflow-faults.sh

#[[ -f test.txt ]] && echo ls || sed -i 's/#testcase_num=5/testcase_num=2/g' guitar/modules/gui-model-adr/resources/user-scripts/adr-sample-workflow-faults.sh

#[[ -f test.txt ]] && echo ls || sed -i '/adb uninstall $aut_package/ i\ adb devices' guitar/modules/gui-model-adr/resources/user-scripts/adr-sample-workflow-faults.sh

#[[ -f test.txt ]] && echo ls || touch test.txt

cd guitar
ant adr.dist
cd ..
cp scripts-1/parser.rb guitar/dist/guitar/parser.rb
cd guitar
cd dist/guitar
chmod +x `find . -name '*.sh'`

#LotsoIntents
./adr-intents-faults.sh LotsoIntents16Activities rohan.makes.intents LotsoIntents16ActivitiesActivity result -no-window

#move masterLog files to the scripts folder
cd ../../..
cp -r guitar/dist/guitar/logs scripts-1
cd scripts-1

echo "You can now run the menu script.  For test names type in \"ls logs\"."