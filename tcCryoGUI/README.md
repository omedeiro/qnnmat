# Tc Cryostat GUI

A MATLAB application for measuring the critical temperature of thin film superconductors. 

remote desktop: qnn-lab2.mit.edu

![gui_t1](/tcCryoGUI/docs/images/gui_v1_t1.PNG)



## Test Connections
The test connections frame is located in the top right of the GUI. There are two columns of disabled field boxes, a list of current values and a Test Connections button. 
By clicking Test Connections button, the mean resistance across each sample is displayed in the left column and the standard deviation of the measurements is displayed on the right column. These values are calculated from a array of 50 measurements and will continue to update while the button is depressed. 

It is important to monitor these values while the PCB is being mounted. Beware of fixed resistance, or 0 Std. readings, as this indicates an improper connection.  There is also a problem with the ADC used by the LabJack that causes issue with these readings where there are no "dummy" samples. Without dummy samples it might appear that a position is broken. 

Even with dummy samples there can still be issues with connections. For example, when tighting the PCB completely the connection at two positions would fail, but by loosening two screws slightly the connection would return. After lowering the current (300uA to 100uA) the PCB could be tightened completely without loosing connection. 


## Cooldown

![gui_t2](/tcCryoGUI/docs/images/gui_v1_t2.PNG)


## Tc Measurement
Below is an example of a typical cooldown/measurement process. At the beginning of the loop you can see the cooldown panel with key metrics: Temperature, Min Temp, and distance. Here distance is the number of measurements between the current measurement and the Min Temp measurement. When distance is > 30 (an arbitrary selection) the cool down is mostly flat and the Tc measurement will begin automatically. 

At the start of the Tc Measurement the GUI window changes from cooldown to 6 R-T plots, representing each sample in the Tc cryo. The heater is then turned on with a setpoint of 25K. Once the setpoint is reached the heater is turned off and a low temperature setpoint is set (the minimum temperature from the cooldown). When the temperature is within 10% of the low setpoint the measurement is complete and Tc is calculated. 

All plots are saved as .mat files, both locally and to the network.
![running](/tcCryoGUI/docs/images/running.gif)

## Troubleshooting
- Unrecognized property 'filePathNAS' for class 'tcCryoApp'.
	- This error comes from an undefined property, ie not initalized in the properties section of the app. But if you look filePathNAS is initialized, so I am not sure why this error occurs. If you run clear all before running the app the error goes away. 


### Electrical

### Mechanical 


## TO-DO
- ~Make Temperature and min(Temperature) run continuously~ quick measure button  
- regex check on case for sample name!!!!!
- ~Better handeling of cooldown during Tc Measurement. Similar to minimum temperature detection used during cooldown (ie distance).~ I think the current method is fine. Stops at +10% of the low setpoint.
- Better handeling of poor/noisy data. 
	- ~Calculate Tc using diff()~ This might not work (noise diff() could be high) Just need more conditions.
	- Calculate RRR
- 
