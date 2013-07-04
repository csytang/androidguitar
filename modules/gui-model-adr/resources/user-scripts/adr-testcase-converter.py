# coding=utf-8
import os
import sys
sys.path.append(os.getcwd() + '/jars/guitar-lib/gui-capture-adr.jar')
from com.android.monkeyrunner import MonkeyRunner
# User action Capture tool
from edu.umd.cs.guitar.capture import ADRCaptureTool    

CMD_MAP = {
    'TOUCH': lambda dev, arg: dev.touch(**arg),
    'DRAG': lambda dev, arg: dev.drag(**arg),
    'PRESS': lambda dev, arg: dev.press(**arg),
    'TYPE': lambda dev, arg: dev.type(**arg),
    'WAIT': lambda dev, arg: MonkeyRunner.sleep(**arg)
    }

# Process a single file for the specified device.
def process_file(fp, device):
    for line in fp:
        print (line)
        (cmd, rest) = line.split('|')
        try:
            # Parse the pydict
            rest = eval(rest)
        except:
            print 'unable to parse options'
            continue

        if cmd not in CMD_MAP:
            print 'unknown command: ' + cmd
            continue

       # Here (before we’ve sent the command from recorded_actions to the emulator),
       # we send the command to our pseudo-ripper for conversion. We are sort of assuming the
       # command will be of the “TOUCH” type here, as GUITAR doesn’t support other stuff. We
       # can deal with other cases here in the Python code (probably by ignoring them). Also I think
       # “rest[‘x’]” and “rest[‘y’]” below get the x and y coordinate out of the command, but haven’t
       # tested these.

        ADRCaptureTool.convert_command(rest['x'], rest['y'])

       # Now back in python, we execute the command from recorded_actions.txt (or whatever the
       # original test case file was called). We will already know if the command should activate a
       # component.

        CMD_MAP[cmd](device, rest)

       # Note: I had to insert this sleep statement here. If commands are sent too quickly over the
       # socket to the emulator, the emulator gets overwhelmed and just shuts down entirely. 5 is
       # in seconds, and was enough for me on VM, so feel free to shorten this by a bit if you want.

        MonkeyRunner.sleep(5)

def main():
    print 'Started test case conversion to tst format.'
    file = sys.argv[1]
    fp = open(file, 'r')
    device = MonkeyRunner.waitForConnection()
    print 'Waiting for connection to emulator...'
    process_file(fp, device)
    fp.close();
    print 'Finished successfully.'

    # At the end of main, we call another static java method to create and dump the test case file
    ADRCaptureTool.output_testcase_file('some_name.tst')
   
if __name__ == '__main__':
    main()
