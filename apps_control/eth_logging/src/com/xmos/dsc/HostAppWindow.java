package com.xmos.dsc;

import java.awt.BorderLayout;
import java.awt.Dimension;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.*;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetAddress;
import java.net.Socket;
import java.net.UnknownHostException;

import javax.swing.JButton;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JTextField;

import org.jfree.ui.ApplicationFrame;

public class HostAppWindow extends ApplicationFrame implements ActionListener
{
	private static final long serialVersionUID = 1L;
	private Socket skt;
	private InputStream n_in;
	private OutputStream n_out;
	private JPanel chartPanel;
	private Integer is_connected = 0;
	private byte[] buf = new byte[1024];
	private byte[] tx_buf = new byte[2];
	private byte[][] data_buf = new byte[262144][128];

    /**
     * Creates a new demo.
     *
     * @param title  the frame title.
     */
    public  HostAppWindow(String title)
    {
        super(title);
        chartPanel = createPanel();
        chartPanel.setPreferredSize(new Dimension(500,50));
        setContentPane(chartPanel);

    }

    public JPanel createPanel()
    {
        JPanel panel = new JPanel(new BorderLayout());

        JLabel ip_lbl = new JLabel("IP Address: ");
        JTextField ip_input = new JTextField();
        JButton btn_connect = new JButton("Dump Log");

        btn_connect.addActionListener(this);

        JPanel connection_pnl = new JPanel(new BorderLayout());
        connection_pnl.setMaximumSize(new Dimension(400, 150));
        connection_pnl.add(ip_input, BorderLayout.CENTER);
        connection_pnl.add(ip_lbl, BorderLayout.NORTH);
        connection_pnl.add( btn_connect, BorderLayout.EAST);
        panel.add(connection_pnl, BorderLayout.NORTH);

        return panel;
    }

    public void actionPerformed(ActionEvent e)
	{
		JPanel ip_pnl = (JPanel)chartPanel.getComponent(0); // get the top panel containing Ip addr
		JTextField ip_addr_txt = (JTextField)ip_pnl.getComponent(0);
		Integer val=0,old_val=0,current_loc,current_rec, start_val = 0, my_loc, my_data;

		if ( is_connected == 0 )
		{
			InetAddress address;
			try
			{
				address = InetAddress.getByName(ip_addr_txt.getText());
			}
			catch (UnknownHostException e1)
			{
				JOptionPane.showMessageDialog(null,"Error: Invalid address or IP","DSC Host Application Error",JOptionPane.ERROR_MESSAGE);
				return;
			}

			try
			{
				skt = new Socket(address, 9596);
				n_in = skt.getInputStream();
				n_out = skt.getOutputStream();

				is_connected = 1;
			}
	        catch (IOException e1)
	        {
				JOptionPane.showMessageDialog(null,"Error: Failed to connect, exiting...","DSC Host Application Error",JOptionPane.ERROR_MESSAGE);
				System.exit(1);
			}
			//JButton btn = (JButton) e.getSource();
			//btn.setEnabled(false);
		}

		if ( is_connected == 1 )
		{
			try
			{
			    //  System.err.println("Error: " + e.getMessage());
			    System.out.println("Getting data...");

				// Tell the DSC board to send the data
	        	buf[0] = 'g';
	        	buf[1] = 'o';
	        	n_out.write(buf, 0, 2);

	        	// For the size of the memory
	        	for ( int i = 0; i < 262144; i+=8 )
	        	{
	        		// Read in 1 packet = 8 x (32 x 4) = 8 x 128 bytes = 1024 bytes
	        		while ( n_in.read(buf,0,1024) < 1024 )
	        		{
	        		}

	        		//
	        		old_val = val;
	        		val = ((0xFF & buf[0]) << 24) + ((0xFF & buf[1]) << 16) + ((0xFF & buf[2]) << 8) + (0xFF & buf[3]);

	        		if ( val != ( old_val + 8 ) )
	    			{
	    				System.out.println("not equal! val = " + Integer.toString(val) + " old_val = " + Integer.toString(old_val) + "\n" );
	    			}

	    			// If it is not the last packet
	    			if ( i != (262144 - 8) )
	    			{
	    				// Force the sending of an ACK back
	    				tx_buf[0] = 'A';
	    				n_out.write(tx_buf, 0, 1);
	    			}

	    			// Copy the packets over to the data buffer
	    			for ( int j = 0; j < 8; j++ )
		        	{
	    				current_rec = i + j;
	    				current_loc = j * 128;

		    			// Copy the packets over to the data buffer
		    			for ( int k = 0; k < 128; k++ )
			        	{
		    				data_buf[current_rec][k] = buf[current_loc + k];
			        	}
		        	}
	        	}

	        	System.out.println("Got all data!");

	        	// Create file
			    FileWriter fstream = new FileWriter("data.csv");
			    BufferedWriter out = new BufferedWriter(fstream);

				//out.write("rec_num,m1_speed,m1_position,m1_iq,m1_id,m1_ia,m1_ib,m1_ic,m1_pwm1,m1_pwm2,m1_pwm3,m2_speed,m2_position,m2_iq,m2_id,m2_ia,m2_ib,m2_ic,m2_pwm1,m2_pwm2,m2_pwm3\n");

        		val = ((0xFF & data_buf[0][0]) << 24) + ((0xFF & data_buf[0][1]) << 16) + ((0xFF & data_buf[0][2]) << 8) + (0xFF & data_buf[0][3]);

				// De-circular buffer here
        		// Loop through the data and find where the record numbers jump
	        	for ( int i = 1; i < 262144; i++ )
	        	{
	        		old_val = val;
	        		val = ((0xFF & data_buf[i][0]) << 24) + ((0xFF & data_buf[i][1]) << 16) + ((0xFF & data_buf[i][2]) << 8) + (0xFF & data_buf[i][3]);

	        		// If the numbers jump, mark this as the start and stop searching.
	        		if ( val != ( old_val + 1 ) )
	        		{
	        			start_val = i;
	        			break;
	        		}
	           	}

				// Dump the last bit of the array of data to the CSV file
	        	for ( int i = start_val; i < 262144; i++ )
	        	{
	        	   	for ( int j = 0; j < (4 * 18); j=j+4 )
	        		{
						my_loc = j;

	        			// Convert the data
	        			my_data = ((0xFF & data_buf[i][my_loc]) << 24) + ((0xFF & data_buf[i][my_loc+1]) << 16) + ((0xFF & data_buf[i][my_loc+2]) << 8) + (0xFF & data_buf[i][my_loc+3]);

	        			// Write the data to a file,
						out.write(Integer.toString(my_data) + ",");
					}

					my_loc = 18 * 4;

					// Convert the 18th value
        			my_data = ((0xFF & data_buf[i][my_loc]) << 24) + ((0xFF & data_buf[i][my_loc+1]) << 16) + ((0xFF & data_buf[i][my_loc+2]) << 8) + (0xFF & data_buf[i][my_loc+3]);

        			// Write the data to a file,
					out.write(Integer.toString(my_data) + "\n");
	        	}

	        	// Dump the first bit of the array of data to the CSV file
	        	for ( int i = 0; i < start_val; i++ )
	        	{
	        	   	for ( int j = 0; j < (4 * 18); j=j+4 )
	        		{
						my_loc = j;

	        			// Convert the data
	        			my_data = ((0xFF & data_buf[i][my_loc]) << 24) + ((0xFF & data_buf[i][my_loc+1]) << 16) + ((0xFF & data_buf[i][my_loc+2]) << 8) + (0xFF & data_buf[i][my_loc+3]);

	        			// Write the data to a file,
						out.write(Integer.toString(my_data) + ",");
					}

					my_loc = 18 * 4;

					// Convert the 18th value
        			my_data = ((0xFF & data_buf[i][my_loc]) << 24) + ((0xFF & data_buf[i][my_loc+1]) << 16) + ((0xFF & data_buf[i][my_loc+2]) << 8) + (0xFF & data_buf[i][my_loc+3]);

        			// Write the data to a file,
					out.write(Integer.toString(my_data) + "\n");	        	}

			    //Close the output stream
			    out.close();
			    System.out.println("Written file!");
			    JOptionPane.showMessageDialog(null, "Done!","DSC Host Application Message",JOptionPane.INFORMATION_MESSAGE);
			}
	        catch (IOException e1)
	        {
	        	System.err.println("Error: " + e1.getMessage());
				//JOptionPane.showMessageDialog(null,"Error: Could not get data, exiting...","DSC Host Application Error",JOptionPane.ERROR_MESSAGE);
				System.exit(1);
			}
		}
	}
}
