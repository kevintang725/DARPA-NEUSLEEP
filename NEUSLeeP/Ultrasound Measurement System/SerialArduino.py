import serial
import time

ser = serial.Serial('/dev/cu.usbmodem1301', 115200)

# Initialize Scan Parameters
dimension_mm = 6;  # in mm
X_Increment = 0.2;  # in mm
Y_Increment = 0.2;  # in mm
Z_Increment = 0.2;  # in mm
X_Dim = dimension_mm/X_Increment;
Y_Dim = dimension_mm/Y_Increment;
Z_Dim = dimension_mm/Z_Increment;

Sample_Delay_Motor = 0.1;
Reset_Delay_Motor = 1;
Buffer_Delay_Motor = 1;

X = 0;
Y = 0;
Z = 0;

# Place Hydrophone at Axial Line (Center)
print('Callibration Beginning...')
time.sleep(2)

print('Moving to Origin Z')
data = 'G1 ' + 'Z' + str(-dimension_mm*0.5) + '\n';
Z = Z + -dimension_mm*0.5;
ser.write(data.encode('ascii'))
time.sleep(Buffer_Delay_Motor)

print('Moving to Origin X')
data = 'G1 ' + 'X' + str(-dimension_mm*0.5) + '\n';
X = X + -dimension_mm*0.5;
ser.write(data.encode('ascii'))
time.sleep(Buffer_Delay_Motor)


# Begin Scanning
print('Begin Scanning...')
print(f'{X:.2f}' + f',{Y:.2f}' + f',{Z:.2f}')
for y in range (int(Y_Dim)):
    for x in range(int(X_Dim)):
        for z in range(int(Z_Dim)):
            data = 'G1 ' + 'X' + str(X_Increment) + '\n';  # Setup Serial Command
            X = X + X_Increment;                    # Update X Coordinate
            ser.write(data.encode('ascii'))               # Send Serial Command for X Motor
            time.sleep(Sample_Delay_Motor)                         # Pause 1.5 seconds
            #print(data)
            print(f'{X:.2f}' + f',{Y:.2f}' + f',{Z:.2f}')

        data = 'G1 ' + 'X' + str(-X_Dim*X_Increment) + '\n';  # Send Serial Command for X Motor
        X = X + -X_Dim*X_Increment;                    # Update X Coordinate
        ser.write(data.encode('ascii'))               # Send Serial Command for X Motor
        time.sleep(Reset_Delay_Motor)                           # Pause 4 seconds
        data = 'G1 ' + 'Z' + str(Z_Increment) + '\n';  # Send Serial Command for X Motor
        Z = Z + Z_Increment;
        ser.write(data.encode('ascii'))               # Send Serial Command for Y Motor
        time.sleep(Sample_Delay_Motor)                         # Pause 1.5 seconds
        #print(data)
        print(f'{X:.2f}' + f',{Y:.2f}' + f',{Z:.2f}')

    data = 'G1 ' + 'Z' + str(-Z_Dim*Z_Increment) + '\n';  # Send Serial Command for X Motor
    Z = Z + -Z_Dim*Z_Increment;
    ser.write(data.encode('ascii'))               # Send Serial Command for Y Motor
    time.sleep(Reset_Delay_Motor)
    data = 'G1 ' + 'Y' + str(Y_Increment) + '\n';  # Send Serial Command for X Motor
    Y = Y + Y_Increment;
    ser.write(data.encode('ascii'))               # Send Serial Command for Y Motor
    time.sleep(Sample_Delay_Motor)                         # Pause 1.5 seconds
    #print(data)
    print(f'{X:.2f}' + f',{Y:.2f}' + f',{Z:.2f}')


ser.close()
