package com.xmos.dsc;
import org.jfree.ui.RefineryUtilities;

public class DscHostApp {

	/**
	 * @param args
	 */
	public static void main(String[] args) 
	{
		HostAppWindow appDisplay = new HostAppWindow("XMOS DSC CAN Control Application");
		appDisplay.pack();
	    RefineryUtilities.centerFrameOnScreen(appDisplay);
	    appDisplay.setVisible(true);
	    appDisplay.populate();
	    appDisplay.run_meters();
	}
	

}
