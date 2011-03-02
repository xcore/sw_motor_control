package com.xmos.dsc;

import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Dimension;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
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
import javax.swing.JSlider;
import javax.swing.JTextField;
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
	private Socket skt;
	private InputStream n_in;
	private OutputStream n_out;
	private JPanel chartPanel;
	private int send_setting_flg = 0;
	private byte[] buf = new byte[1024];
	private int connected = 0;
    
    /**
     * Creates a new demo.
     *
     * @param title  the frame title.
     */
    public  HostAppWindow(String title) {
        super(title);
        chartPanel = createPanel();
        chartPanel.setPreferredSize(new Dimension(500,600));
        setContentPane(chartPanel);
        
    }
    
    private JFreeChart createChart(ValueDataset dataset) {
    	
        MeterPlot plot = new MeterPlot(dataset);
        plot.addInterval(new MeterInterval("Over Current", new Range(3000, 4000), null, null, Color.RED));
        plot.addInterval(new MeterInterval("High", new Range(2000, 3000), null, null, new Color(238,245,42)));
        plot.addInterval(new MeterInterval("Normal", new Range(0, 2000), null, null, new Color(32,212,44)));
        plot.setOutlinePaint(Color.black);
        plot.setBackgroundPaint(Color.white);
        plot.setNeedlePaint(Color.white);
        plot.setRange(new Range(0, 4000));
        plot.setUnits("RPM");
        plot.setTickLabelsVisible(true);
   
        chart = new JFreeChart("Motor Speed", 
                JFreeChart.DEFAULT_TITLE_FONT, plot, false);
        return chart;
    }
    
    public JPanel createPanel() {
        dataset = new DefaultValueDataset(0);
        
        JFreeChart chart = createChart(dataset);
        JPanel panel = new JPanel(new BorderLayout());
        
        /* rpm setting slider */
        JSlider rpm_set = new JSlider();
        rpm_set.setMinimum(0);
        rpm_set.setMaximum(3500);
        rpm_set.setValue(0);
        rpm_set.setMajorTickSpacing(500);
        rpm_set.setMinorTickSpacing(100);
        rpm_set.setPaintLabels(true);
        rpm_set.setPaintTicks(true);
        rpm_set.setEnabled(false);
        
        rpm_set.addChangeListener(new ChangeListener() {
            public void stateChanged(ChangeEvent e) {
                send_setting_flg = 1;
            }
        });
        
        
        JLabel ip_lbl = new JLabel("IP Address: ");
        JTextField ip_input = new JTextField();
        JButton btn_connect = new JButton("Connect");
        
        btn_connect.addActionListener(this);
        
        JPanel connection_pnl = new JPanel(new BorderLayout());
        connection_pnl.setMaximumSize(new Dimension(400, 150));
        connection_pnl.add(ip_input, BorderLayout.CENTER);
        connection_pnl.add(ip_lbl, BorderLayout.NORTH);
        connection_pnl.add( btn_connect, BorderLayout.EAST);
        
        panel.add(new ChartPanel(chart));
        panel.add(rpm_set, BorderLayout.SOUTH);
        panel.add(connection_pnl, BorderLayout.NORTH);
        return panel;
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
		JPanel ip_pnl = (JPanel)chartPanel.getComponent(2); // get the top panel containing Ip addr
		JTextField ip_addr_txt = (JTextField)ip_pnl.getComponent(0);
		
		InetAddress address;
		try {
			address = InetAddress.getByName(ip_addr_txt.getText());
		} catch (UnknownHostException e1) {
			JOptionPane.showMessageDialog(null,"Error: Invalid address or IP","DSC Host Application Error",JOptionPane.ERROR_MESSAGE);
			return;
		}
        try {
			skt = new Socket(address, 9595);
			n_in = skt.getInputStream();
			n_out = skt.getOutputStream();
			
			System.out.println("Waiting to connect...");
	        
        	buf[0] = 'g';
        	buf[1] = 'o';
        	n_out.write(buf, 0, 2);
        	
        	System.out.println("Connected");
        	
        	JSlider slider = (JSlider) chartPanel.getComponent(1);
        	slider.setEnabled(true);
			
		} catch (IOException e1) {
			JOptionPane.showMessageDialog(null,"Error: Failed to connect, exiting...","DSC Host Application Error",JOptionPane.ERROR_MESSAGE);
			System.exit(1);
		}
		JButton btn = (JButton) e.getSource();
		btn.setEnabled(false);
		
		connected = 1;
	}
    
    public void run_meters()
    {
		
		int speed = 0;
		int set_speed = 0;
		
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
					buf[0] = 's';
					buf[1] = 'p';
					buf[2] = 'e';
					buf[3] = 'e';
					buf[4] = 'd';
					n_out.write(buf, 0, 5);

					n_in.read(buf,0,4);

					speed += ((0xFF & buf[3]) << 24);
					speed += ((0xFF & buf[2]) << 16);
					speed += ((0xFF & buf[1]) <<  8);
					speed += ((0xFF & buf[0]) <<  0);

					n_in.read(buf,0,4);
					set_speed = ((0xFF & buf[3]) << 24);
					set_speed += ((0xFF & buf[2]) << 16); 
					set_speed += ((0xFF & buf[1]) <<  8);
					set_speed += ((0xFF & buf[0]) <<  0);

					speed = speed/2;
					this.setCurrentMeterValue(speed);

					if (send_setting_flg != 0)
					{

						JSlider slider = (JSlider) this.chartPanel.getComponent(1);
						int val = slider.getValue();

						buf[0] = 's';
						buf[1] = 'e';
						buf[2] = 't';
						buf[3] = (byte) (val);
						buf[4] = (byte) (val >>> 8);
						buf[5] = (byte) (val >>> 16);
						buf[6] = (byte) (val >> 24);

						send_setting_flg = 0;

						n_out.write(buf, 0, 7);
					} else this.setCurrentSpeedSetting(set_speed);
				}
			} catch (IOException e) {
				JOptionPane.showMessageDialog(null,"Error: IO Exception, exiting...","DSC Host Application Error",JOptionPane.ERROR_MESSAGE);
				System.exit(2);
			}
		}
    }

}
