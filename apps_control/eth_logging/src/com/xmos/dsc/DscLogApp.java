package com.xmos.dsc;
import org.jfree.ui.RefineryUtilities;

public class DscLogApp {

	/**
	 * @param args
	 */
	public static void main(String[] args)
	{
		HostAppWindow appDisplay = new HostAppWindow("XMOS DSC Ethernet Logging Application");
		appDisplay.pack();
	    RefineryUtilities.centerFrameOnScreen(appDisplay);
	    appDisplay.setVisible(true);
	}
}
