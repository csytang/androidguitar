package edu.umd.cs.guitar.event;

import java.util.Hashtable;
import java.util.List;

import edu.umd.cs.guitar.model.GComponent;
import edu.umd.cs.guitar.model.GObject;

public class ADREvent implements GEvent {

	@Override
	public boolean isSupportedBy(GObject gComponent) {
		// TODO Auto-generated method stub
		return false;
	}

	@Override
	public void perform(GObject gComponent, List<String> parameters,
			Hashtable<String, List<String>> optionalData) {
		// TODO Auto-generated method stub

	}

	@Override
	public void perform(GObject gComponent,
			Hashtable<String, List<String>> optionalData) {
		// TODO Auto-generated method stub

	}

}
