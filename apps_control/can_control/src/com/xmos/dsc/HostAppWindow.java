package com.xmos.dsc;

import gnu.io.*;

import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Dimension;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

import javax.swing.JButton;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JSlider;
import javax.swing.JComboBox;
import javax.swing.event.ChangeEvent;
import javax.swing.event.ChangeListener;

import org.jfree.chart.ChartPanel;
import org.jfree.chart.JFreeChart;
import org.jfree.chart.plot.MeterInterval;
import org.jfree.chart.plot.MeterPlot;
import org.jfree.data.Range;
import org.jfree.data.general.DefaultValueDataset;
import org.jfree.data.general.ValueDataset;
import org.jfree.ui.ApplicationFrame;

public class HostAppWindow extends ApplicationFrame implements ActionListener
{
	private static final long serialVersionUID = 1L;
	private DefaultValueDataset dataset;
	private JFreeChart chart;
	private InputStream n_in;
	private OutputStream n_out;
	private JPanel chartPanel;
	private int send_setting_flg = 0;
	private byte[] buf = new byte[256];
	private int connected = 0;
    
    /**
     * Creates a new demo.
     *
     * @param title  the frame title.
     */
    public  HostAppWindow(String title)
    {
        super(title);
        chartPanel = createPanel();
        chartPanel.setPreferredSize(new Dimension(500,600));
        setContentPane(chartPanel);
    }
    
    private JFreeChart createChart(ValueDataset dataset)
    {
        MeterPlot plot = new MeterPlot(dataset);
        plot.addInterval(new MeterInterval("Over Current", new Range(5000, 6000), null, null, Color.RED));
        plot.addInterval(new MeterInterval("High", new Range(4000, 5000), null, null, new Color(238,245,42)));
        plot.addInterval(new MeterInterval("Normal", new Range(0, 4000), null, null, new Color(32,212,44)));
        plot.setOutlinePaint(Color.black);
        plot.setBackgroundPaint(Color.white);
        plot.setNeedlePaint(Color.white);
        plot.setRange(new Range(0, 6000));
        plot.setUnits("RPM");
        plot.setTickLabelsVisible(true);
   
        chart = new JFreeChart("Motor Speed", 
                JFreeChart.DEFAULT_TITLE_FONT, plot, false);
        return chart;
    }
    
    public JPanel createPanel()
    {
        dataset = new DefaultValueDataset(0);
        
        JFreeChart chart = createChart(dataset);
        JPanel panel = new JPanel(new BorderLayout());
        
        // rpm setting slider
        JSlider rpm_set = new JSlider();
        rpm_set.setMinimum(0);
        rpm_set.setMaximum(4600);
        rpm_set.setValue(0);
        rpm_set.setMajorTickSpacing(1000);
        rpm_set.setMinorTickSpacing(100);
        rpm_set.setPaintLabels(true);
        rpm_set.setPaintTicks(true);
        rpm_set.setEnabled(false);
        
        rpm_set.addChangeListener(new ChangeListener()
        {
            public void stateChanged(ChangeEvent e)
            {
                send_setting_flg = 1;
            }
        });
        
        JLabel comm_lbl = new JLabel("COMM PORTS AVAILABLE: ");
        JComboBox comm_input = new JComboBox();
        JButton btn_connect = new JButton("Connect");
        
        btn_connect.addActionListener(this);
        
        JPanel connection_pnl = new JPanel(new BorderLayout());
        connection_pnl.setMaximumSize(new Dimension(400, 150));
        connection_pnl.add(comm_input, BorderLayout.CENTER);
        connection_pnl.add(comm_lbl, BorderLayout.NORTH);
        connection_pnl.add(btn_connect, BorderLayout.EAST);
        
        panel.add(new ChartPanel(chart));
        panel.add(rpm_set, BorderLayout.SOUTH);
        panel.add(connection_pnl, BorderLayout.NORTH);
        return panel;
    }
    
    // Populate the ComboBoxes by asking the Java Communications API what ports it has. Since the initial information comes from
    // a Properties file, it may not exactly reflect your hardware.
    protected void populate()
    {
		JPanel comm_pnl = (JPanel)chartPanel.getComponent(2); // get the top panel containing Ip addr
		JComboBox comm_box = (JComboBox)comm_pnl.getComponent(0);
  	
		// Get the list of ports
        java.util.Enumeration<CommPortIdentifier> portEnum = CommPortIdentifier.getPortIdentifiers();
        
        // Go through the list of ports, and add any serial ports to the combo box
        while ( portEnum.hasMoreElements() ) 
        {    	
    	    CommPortIdentifier portIdentifier = portEnum.nextElement();
    	    
    	    if (portIdentifier.getPortType() == CommPortIdentifier.PORT_SERIAL)
    	    {
    	    	comm_box.setEnabled(true);
    	    	comm_box.addItem(portIdentifier.getName());
    	    }
        }
    }

    public void setCurrentMeterValue( double value )
    {    	
    	dataset.setValue(value);
    }
    
    public void setCurrentSpeedSetting( int value )
    {
    	JSlider slider = (JSlider) this.chartPanel.getComponent(1);
    	slider.setValue(value);
    }
    
    public void actionPerformed(ActionEvent e)
	{
    	// get the top panel containing comm port list
		JPanel comm_pnl = (JPanel)chartPanel.getComponent(2); 
		JComboBox comm_box = (JComboBox)comm_pnl.getComponent(0);
		//String comm_txt = (String)(comm_box.getSelectedItem());
		
        try
        {
        	// Get the currently selected item in the serial port combo box
    		CommPortIdentifier portIdentifier = CommPortIdentifier.getPortIdentifier( (String) comm_box.getSelectedItem() );
    		
    		// Check it isn't currently in use
            if ( portIdentifier.isCurrentlyOwned() )
            {
                System.out.println("Error: Port is currently in use");
            }
            else
            {
                CommPort commPort = portIdentifier.open(this.getClass().getName(),2000);
                
                if ( commPort instanceof SerialPort )
                {
                	// Open the serial port at 115200 8N1, with no flow control
                    SerialPort serialPort = (SerialPort) commPort;
                    serialPort.setSerialPortParams(115200,SerialPort.DATABITS_8,SerialPort.STOPBITS_1,SerialPort.PARITY_NONE);
                    serialPort.setFlowControlMode(SerialPort.FLOWCONTROL_NONE);
                    
                    // Assign the input and output streams
                    n_in = serialPort.getInputStream();
                    n_out = serialPort.getOutputStream();

                    // Clear the input buffer?
                    
                    
                    // Setup the CAN adapter
                    try
                    {                
	                    // Close the CAN adapter if open
                    	n_out.write('C');
                    	n_out.write('\r');
	
	                    // Set the speed to 1Mbps
                    	n_out.write('S');
                    	n_out.write('6');
                    	n_out.write('\r');                	
                    	
	                    // Open the CAN adapter
                    	n_out.write('O');
                    	n_out.write('\r');
                    	
	                    // Clear the flags
                    	n_out.write('F');
                    	n_out.write('\r');                    	

	                    // Clear the flags
                    	n_out.write('F');
                    	n_out.write('\r');                      	
                    	
	                    // Clear the flags
                    	n_out.write('F');
                    	n_out.write('\r');                      	
                    	
                    	// Enable the slider to set the speed
                    	JSlider slider = (JSlider) chartPanel.getComponent(1);
                    	slider.setEnabled(true);                    	
                    }
                    catch ( IOException g )
                    {
                        g.printStackTrace();
                    }         
                }
                else
                {
                    System.out.println("Error: Only serial ports are handled by this example.");
                }
            }   
        }
        catch ( Exception f )
        {
            // TODO Auto-generated catch block
//			JOptionPane.showMessageDialog(null,"Error: Invalid address or IP","DSC Host Application Error",JOptionPane.ERROR_MESSAGE);
            f.printStackTrace();
        }

        // Disable the button
		JButton btn = (JButton) e.getSource();
		btn.setEnabled(false);
	
		// Update the data
		connected = 1;
	}
       

    public void run_meters()
    {
    	int i = 0;
		int speed = 0;
		int set_speed = 0;
		int len = 0;
		
		while (true)
		{
			try {
				Thread.sleep(1000);
			} catch (InterruptedException e1) {
				e1.printStackTrace();
			}
			
			try {
				while (connected == 1)
				{
					buf[0] = 't'; // Send packet
					buf[1] = '0'; // A
					buf[2] = '0';
					buf[3] = '1';
					buf[4] = '8'; // Length of data
					buf[5] = '0'; // Byte 0 = MSB Of Address
					buf[6] = '0';
					buf[7] = '0'; // Byte 1 = LSB Of Address
					buf[8] = '2';
					buf[9] = '0'; // Byte 2 = Command
					buf[10] = '1';
					buf[11] = '0'; // Byte 3
					buf[12] = '0';
					buf[13] = '0'; // Byte 4
					buf[14] = '0';
					buf[15] = '0'; // Byte 5
					buf[16] = '0';
					buf[17] = '0'; // Byte 6
					buf[18] = '0';
					buf[19] = '0'; // Byte 7
					buf[20] = '0';
					buf[21] = '\r';
					// 22 bytes total
					
					// Write the data out
					i = 0;
					
					while ( i < 22 )
					{
						n_out.write(buf[i]);
						i++;
					}
					
					// Read in packet here
					buf[0] = '0';
					len = n_in.read(buf);

					// Find the first t in a packet
					String temp_str = new String(buf,0,len);
					int first_t =  temp_str.indexOf('t');

					// If we have a data packet
					if (first_t != -1)
					{
						// Convert the buffer to a string.
						String temp_str_2 = new String(buf,first_t,len);
						
						// Find the first \r in a packet, so we know where the end is
						int first_cr =  temp_str_2.indexOf('\r');
					
						// Check here to make sure the string is long enough
						if ( first_cr >= 25)
						{
							// Check to make sure that the data is for us
							if ( ( buf[first_t + 1] == '0') && ( buf[first_t + 2] == '0') && ( buf[first_t + 3] == '2') )
							{
								// Get the speed from the string
								String str_speed = new String(buf, first_t + 5, 8);
								speed = Integer.parseInt(str_speed, 16);
								//speed = speed/2;
								this.setCurrentMeterValue(speed);
								
								// Get the set point from the string
								String str_set = new String(buf, first_t + 13, 8);
								set_speed = Integer.parseInt(str_set, 16);
								
								// Print out the values
								//System.out.print("Speed " + speed + "\r");
								//System.out.print("Set Speed " + set_speed + "\r");
							}
							else
							{
								JOptionPane.showMessageDialog(null,"Error: CAN Packet not for us, exiting...","DSC Host Application Error",JOptionPane.ERROR_MESSAGE);
								System.exit(2);
							}
						}
																	
						// If the slider value has been updated
						if (send_setting_flg != 0)
						{
							// Get the value from the slider
							JSlider slider = (JSlider) this.chartPanel.getComponent(1);
							int val = slider.getValue();
	
							// Setup the packet data
							buf[0] = 't'; // Send packet
							buf[1] = '0'; // A
							buf[2] = '0';
							buf[3] = '1';
							buf[4] = '8'; // Length of data
							buf[5] = '0'; // Byte 0 = MSB Of Address
							buf[6] = '0';
							buf[7] = '0'; // Byte 1 = LSB Of Address
							buf[8] = '2';
							buf[9] = '0'; // Byte 2 = Command
							buf[10] = '2';
							buf[11] = '0'; // Byte 3 = MSB of Data
							buf[12] = '0';
							buf[13] = '0'; // Byte 4 = Data
							buf[14] = '0';
							buf[15] = '0'; // Byte 5 = Data
							buf[16] = '0';
							buf[17] = '0'; // Byte 6 = LSB Of Data
							buf[18] = '0';
							buf[19] = '0'; // Byte 7
							buf[20] = '0';
							buf[21] = '\r';
							// 22 bytes total
	
							// t 001 8 00 02 02 00 01 07 70 00
							
							// Convert the set speed to a value to octal.
							String my_val = Integer.toHexString(val);
							
							i = 0;
							int j = 19 - my_val.length();
													
							while ( i < my_val.length() )
							{
								buf[j+i] = (byte) my_val.charAt(i);
								i++;
							}
							
							// Reset the data flag
							send_setting_flg = 0;
	
	 						//System.out.print(my_val + "\r");
							//System.out.print(new String(buf,0,22) + "\r");
			
							// Send the packet here
							i = 0;
							while ( i < 22 )
							{
								
								n_out.write(buf[i]);
								i++;
							}
						}
						else this.setCurrentSpeedSetting(set_speed);
					}
				}
			} catch (IOException e) {
				JOptionPane.showMessageDialog(null,"Error: IO Exception, exiting...","DSC Host Application Error",JOptionPane.ERROR_MESSAGE);
				System.exit(2);
			}
		}
    }

}
