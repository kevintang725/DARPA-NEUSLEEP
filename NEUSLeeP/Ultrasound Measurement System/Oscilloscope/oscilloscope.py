import pyvisa as visa
import numpy as np
from struct import unpack
import sys
import pylab
import time

# Establish Connection
rm = visa.ResourceManager() # Calling PyVisaPy library
scope = rm.open_resource('USB0::0xF4ED::0xEE3A::SDS1EDEC5R1189::INSTR') # Connecting via USB
#scope.timeout = 100
#scope.termination = '\n'
#scope = rm.open_resource('TCPIP::192.16.13.181::INSTR') # Connecting via LAN

# Check for Connection Established
scope.write("*IDN?")
print(scope.read())

# Read Oscilloscope Paramters
print('Oscilloscope Parameter Settings')
scope.write("SARA?")
sample_rate = scope.read()
scope.write("Time_DIV?")
time_div = scope.read()
scope.write("C1:Volt_Div?")
CH1_YScale = scope.read()
scope.write("C2:Volt_Div?")
CH2_YScale = scope.read()
scope.write("C1:OFST?")
CH1_Offset = scope.read()
scope.write("C2:OFST?")
CH2_Offset = scope.read()
print('Sample Rate:' + sample_rate)
print('Time Division:' + time_div)
print('CH1 Scale:' + CH1_YScale)
print('CH1 Offset:' + CH1_Offset)
print('CH2 Scale:' + CH2_YScale)
print('CH2 Offset:' + CH2_Offset)

# Read Waveform Data
#scope.write("CURV?")
scope.query_binary_values('C1:WF?', datatype='d', is_big_endian=True)
CH1_WaveForm = scope.read()
print(CH1_WaveForm)

#code value *( vdiv /25)- voffset. code value: The decimal of wave data .



# Plotting Volt Vs. Time
#pylab.plot(Time, Volts)
#pylab.show()
