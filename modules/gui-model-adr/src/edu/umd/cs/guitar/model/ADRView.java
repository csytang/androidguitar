package edu.umd.cs.guitar.model;

import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.ExpandableListView;
import android.widget.ListView;
import android.widget.TextView;


public class ADRView {
	public String type;
	public int id;
	public int viewId; //jing's added item
	public View curView; //jing's added item
	public boolean isClickable;
	public boolean isLongClickable;
	public String text;
	public int x;
	public int y;
	public int childCount = 0;
	public boolean isExpandable;
	

	public ADRView(View v) {
		this.type = v.getClass().getName();
		this.id = extractID(v);
		this.viewId = v.getId();
		this.curView = v.getRootView();
		this.isClickable = v.isClickable();
		this.isLongClickable = v.isLongClickable();
		if (v instanceof TextView) {
			this.text = ((TextView)v).getText().toString();
		} else if (v instanceof Button) {
			this.text = ((Button)v).getText().toString();
		} else {
			this.text = this.type;
		}
		final int[] xy = new int[2];
		v.getLocationInWindow(xy);
		this.x = xy[0];
		this.y = xy[1];
		if (v instanceof ViewGroup) {
			this.childCount = ((ViewGroup)v).getChildCount();
		}
		this.isExpandable = this.isClickable;
		if (v instanceof ListView || v instanceof ExpandableListView) {
			// due to trackball issue, it's not expandable even though it's clickable
			this.isExpandable = false;
		} else if (v instanceof TextView &&
				v.getParent() != null && ((View)v.getParent()).isClickable()) {
			this.isExpandable = true;
		}
	}
	
	public int returnID(){
		if(this.id == 0){
			/*error no ID is imprinted*/
		 return -1;	
		}else{
		 return this.id;
		}
	}
	
	public int returnViewId(){
		//view id should be positive, if -1 then it means no view id which is an error in our case
		return viewId;
	}
	
	public static int extractID(View v) {
		String str = v.toString();
		int at = str.indexOf('@');
		return Integer.parseInt(str.substring(at+1), 16);
	}

	public String toString() {
		String ret = type + "@" + Integer.toHexString(id);
		return ret;
	}
}
