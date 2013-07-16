#!/usr/bin/env monkeyrunner

from com.android.monkeyrunner import MonkeyRunner as mr
from com.android.monkeyrunner.recorder import MonkeyRecorder
MonkeyRecorder.start(mr.waitForConnection())
