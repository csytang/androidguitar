/*
 *  Copyright (c) 2009-@year@. The  GUITAR group  at the University of
 *  Maryland. Names of owners of this group may be obtained by sending
 *  an e-mail to atif@cs.umd.edu
 *
 *  Permission is hereby granted, free of charge, to any person obtaining
 *  a copy of this software and associated documentation files
 *  (the "Software"), to deal in the Software without restriction,
 *  including without limitation  the rights to use, copy, modify, merge,
 *  publish,  distribute, sublicense, and/or sell copies of the Software,
 *  and to  permit persons  to whom  the Software  is furnished to do so,
 *  subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included
 *  in all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 *  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 *  MERCHANTABILITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 *  IN NO  EVENT SHALL THE  AUTHORS OR COPYRIGHT  HOLDERS BE LIABLE FOR ANY
 *  CLAIM, DAMAGES OR  OTHER LIABILITY,  WHETHER IN AN  ACTION OF CONTRACT,
 *  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 *  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
package edu.umd.cs.guitar.testcase.data;

import org.kohsuke.args4j.CmdLineException;
import org.kohsuke.args4j.CmdLineParser;

import edu.umd.cs.guitar.model.IO;
import edu.umd.cs.guitar.model.data.EFG;
import edu.umd.cs.guitar.util.GUITARLog;

/**
 * @author <a href="mailto:baonn@cs.umd.edu"> Bao Nguyen </a>
 * 
 */
public class TestCaseDataPopulatorMain {
	/**
	 * @param args
	 */
	public static void main(String[] args) {
		CmdLineParser parser;
		TestCaseDataPopulatorConfiguration configuration = new TestCaseDataPopulatorConfiguration();
		parser = new CmdLineParser(configuration);

		try {
			parser.parseArgument(args);
			if (!configuration.isValid()
					|| (TestCaseDataPopulatorConfiguration.HELP)) {
				throw new CmdLineException("");
			}

		} catch (CmdLineException e) {
			GUITARLog.log.error(e.getMessage());
			GUITARLog.log.error("");
			GUITARLog.log.error("Usage: java [JVM options] "
					+ TestCaseDataPopulator.class.getName() + " [options] \n");

			GUITARLog.log.error("where [TC generator options] include:");
			GUITARLog.log.error("");

			parser.printUsage(System.err);
			System.exit(0);

		}

	}

}