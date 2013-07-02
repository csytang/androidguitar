package edu.umd.cs.guitar.capture;

import java.io.BufferedWriter;
import java.io.OutputStreamWriter;
import java.net.InetSocketAddress;
import java.net.Socket;
import edu.umd.cs.guitar.model.ADRApplication;
import edu.umd.cs.guitar.model.ADRView;
import edu.umd.cs.guitar.model.ADRComponent;

public class ADRCaptureTool {
	
	// Constructor
	public ADRCaptureTool() {
		
	}
	
	// Converts an ordered pair into an eventID by dynamically “ripping” the current state of the emulator, 
	// and reverse engineering which component is currently at the ordered pair. 
	// It will then push the id of that component onto a list to save it.
	public static void convert_command(int x, int y) {
		
	}
	
	// Takes the list that has already been created by successive calls to 
	// convert_command() and actually creates the .tst file (with the filename given by the argument).
	public static void output_testcase_file(String filename) {
		
	}
	
	public static void main(String[] argv) {
		
	}

}
