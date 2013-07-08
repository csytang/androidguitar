package edu.umd.cs.guitar.capture;

/*
 * Just copy the imports and the interior of the method,
 * and makes changes for names and things as necessary.
 */

import java.io.File;
import java.util.Iterator;


import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.InetSocketAddress;
import java.net.Socket;
import edu.umd.cs.guitar.model.ADRApplication;
import edu.umd.cs.guitar.model.ADRView;
import edu.umd.cs.guitar.model.ADRWindow;
import edu.umd.cs.guitar.model.ADRComponent;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;

import org.w3c.dom.Document;
import org.w3c.dom.Element;


import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Set;
import java.util.TreeSet;

import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.ExpandableListView;
import android.widget.ListView;
import android.widget.TextView;

import java.lang.reflect.Type;

public class ADRCaptureTool {

	public static List<String> testcase_events = new ArrayList<String>();
	
	// Constructor
	public ADRCaptureTool() {
		
	}
	
	// Converts an ordered pair into an eventID by dynamically “ripping” the current state of the emulator, 
	// and reverse engineering which component is currently at the ordered pair. 
	// It will then push the id of that component onto a list to save it.
	public static void convert_command(int x, int y) {
		
		//jing's part, assume viewObject is the views i will be given
		
		List<ADRView> viewObjects = new ArrayList<ADRView>();
		Socket socket = null;
		BufferedReader in = null;
		BufferedWriter out = null;
		ADRWindow gWindow;
		String line;
		int gWindowID=-1;
		final int port = 10737;
		
		int e_ID = -1;
		String tst_e_ID = "";
		//This is the list of ADRViews that will be used later to validate the x,y coordinates
				//List<ADRView> viewObjects = new ArrayList<ADRView>();
				
				try {
					socket = new Socket();
					socket.connect(new InetSocketAddress("127.0.0.1", port));

					out = new BufferedWriter(new OutputStreamWriter(socket.getOutputStream()));
					in = new BufferedReader(new InputStreamReader(socket.getInputStream(), "utf-8"));
					//We need to call getRootWindows to get the main window of the application
					out.write("getRootWindows");
					out.newLine();
					out.flush();
					while(!in.ready());
					line = in.readLine();

					gWindow = new ADRWindow(line);
					gWindowID = gWindow.window.getID();
				} catch (IOException ex) {
					try {
						Thread.sleep(500);
					} catch (InterruptedException e1) {
						e1.printStackTrace();
					}
					
				} finally {
					try {
						if (out != null) {
							out.close();
						}
						if (in != null) {
							in.close();
						}
						socket.close();
					} catch (IOException ex) {
						ex.printStackTrace();
					}
				}
				
				
				
				
				Socket socket2 = null;
				BufferedReader in2 = null;
				BufferedWriter out2 = null;
				String line2;
				
				try {
					socket2 = new Socket();
					socket2.connect(new InetSocketAddress("127.0.0.1", port));

					out2 = new BufferedWriter(new OutputStreamWriter(socket2.getOutputStream()));
					in2 = new BufferedReader(new InputStreamReader(socket2.getInputStream(), "utf-8"));
					
					out2.write("getChildren");
					out2.newLine();
					out2.write(String.valueOf(gWindowID));
					out2.newLine();
					out2.flush();
					while(!in2.ready());
					while ((line2 = in2.readLine()) != null) {			
						Type vlst = new TypeToken<ADRView>() {}.getType();		
						Gson gson = new Gson();

						if (line2.equals("END")) break;
						
						ADRView currView = gson.fromJson(line2, vlst);
						
						viewObjects.add(currView);
					}
				} catch (IOException ex) {
					ex.printStackTrace();
				} finally {
					try {
						if (out2 != null) {
							out2.close();
						}
						if (in2 != null) {
							in2.close();
						}
						socket2.close();
					} catch (IOException ex) {
						ex.printStackTrace();
					}
				}
				
				

		
//for loop starts
		for(int i=0; i<viewObjects.size(); i++){
			int[] xy = new int[2];
			viewObjects.get(i).curView.getLocationOnScreen(xy);
			//or viewObjects[i].curView.getLocationInWindow(xy);
			if(xy[0] == x && xy[1] == y){
				e_ID = viewObjects.get(i).returnID();
				//or return viewObjects[i].returnViewId();
			}else{
				continue;
			}
		}
		
		tst_e_ID = "e" + Integer.toString(e_ID);
		System.out.println("Adding testcase step with event ID " + tst_e_ID + ".");
		testcase_events.add(tst_e_ID);
		
		//item cannot be found
		//return -1;
		
		
	}
	
	// Takes the list that has already been created by successive calls to 
	// convert_command() and actually creates the .tst file (with the filename given by the argument).
	public static void output_testcase_file(String filename) {
		DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
		try {
			DocumentBuilder docBuilder = factory.newDocumentBuilder();
			
			Document doc = docBuilder.newDocument();
			Element root = doc.createElement("TestCase");
			doc.appendChild(root);
			
			Iterator<String> iter = testcase_events.iterator();
			boolean reachingStep = true;
			while (iter.hasNext()) {
				String current = iter.next();
				Element step = doc.createElement("Step");
				Element id = doc.createElement("EventId");
				id.setTextContent(current);
				step.appendChild(id);
				Element reaching = doc.createElement("ReachingStep");
				if(reachingStep) {
					reaching.setTextContent("True");
					reachingStep = false;
				}
				else {
					reaching.setTextContent("False");
				}
				step.appendChild(reaching);
				root.appendChild(step);
			}
			TransformerFactory transformFactory = TransformerFactory.newInstance();
			Transformer transform = transformFactory.newTransformer();
			DOMSource source = new DOMSource(doc);
			StreamResult result = new StreamResult(new File (filename));
			transform.transform(source, result);
		} catch (ParserConfigurationException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (TransformerConfigurationException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (TransformerException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	
	}
	
	public static void main(String[] argv) {
		
		
	}

}
