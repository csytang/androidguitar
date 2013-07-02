/*import edu.umd.cs.guitar.model.* ;
import edu.umd.cs.guitar.model.data.* ;*/

/*import edu.umd.cs.guitar.model.* ;
import edu.umd.cs.guitar.model.data.* ;*/

import java.awt.Frame ;
import java.awt.Button ;

import java.util.List ;

public class GuitarJFCTest {
	public static void main(String[]args) {
		Frame frame = new Frame("testing") ;
		frame.setSize(100,100) ;
		Button button1 = new Button("button1") ;
		Button button2 = new Button("button2") ;
		frame.add(button1) ;
		frame.add(button2) ;
		frame.add(new Button("button3")) ;
		frame.setVisible(true) ;

		/*JFCXWindow jfcWindow = new JFCXWindow(frame) ;
		System.out.println("This is the test") ;
		System.out.println(jfcWindow.toString()) ;
		System.out.println(jfcWindow.extractGUIProperties()) ;
		GUIType gui = jfcWindow.extractGUIProperties() ;
		ContainerType container = gui.getContainer() ;
		System.out.println(container.getContents().getWidgetOrContainer().size()) ;
		System.out.println(jfcWindow.getContainer().hasChildren()) ;
		System.out.println(jfcWindow.getContainer().getChildren().size()) ;

		GUIStructure structure = new GUIStructure() ;
		structure.getGUI().add(gui) ;

		for(GComponent component : jfcWindow.getContainer().getChildren()) {
			System.out.println("\t" + component.hasChildren()) ;
			gui.getContainer().getContents().getWidgetOrContainer().add(component.extractProperties()) ;
		}

		IO.writeObjToFile(structure, "test.xml") ; */
	}
}
