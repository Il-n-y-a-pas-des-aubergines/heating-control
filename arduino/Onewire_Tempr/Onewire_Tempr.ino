#include <OneWire.h>
#include <DallasTemperature.h>


// im PC Terminal ausgeben mit:
// $ cat /dev/ttyACM0

// Wertebereich der Sensoren:
// -127..+85 (?) °C
// treten gelegentlich beim ein- und ausstecken auf.

// Data wire is plugged into pin 2 on the Arduino
#define ONE_WIRE_BUS 2

// Setup a oneWire instance to communicate with any OneWire devices (not just Maxim/Dallas temperature ICs)
OneWire oneWire(ONE_WIRE_BUS);

// Pass our oneWire reference to Dallas Temperature. 
DallasTemperature sensors(&oneWire);

// arrays to hold device addresses
DeviceAddress sensor_adr[20];

// beliebige Strings
String string;
// in Unterfunktionen
char string50[51];
// Geräteadressen
char string16[17];


// ----------------------------------
void setup(void)
{
  // start serial port
  Serial.begin(9600);
  //Serial.println("------------------------------------------");
  //Serial.println("Dallas Temperature IC Control Library Demo");
  Serial.println("[InitArduino]");

  // Start up the library
  sensors.begin(); // IC Default 9 bit. If you have troubles consider upping it 12. 
                   // Ups the delay giving the IC more time to process the temperature measurement
  delay(1000);        // delay in between reads for stability

}


// ----------------------------------
void loop(void)
{ 
  DeviceAddress addr;
  
  sensors.begin(); // IC Default 9 bit. If you have troubles consider upping it 12. 
  delay(50);       // delay in between reads for stability

  sensors.requestTemperatures(); // Send the command to get temperatures
  
  // Schleife, die die Werte aller gefundenen Sensoren ausgibt
  string = "[";
  for (int i = 0; i < sensors.getDeviceCount(); i++) {
    sensors.getAddress(addr, i);
    string = string + printTemperature(addr);
  }
  string = string + "]";
  Serial.println(string);
  
  delay(5000);        // delay in between reads for stability
  
}

// ----------------------------------
// function to print a device address
char* printAddress(DeviceAddress deviceAddress)
{
  sprintf(string16, "%02x%02x%02x%02x%02x%02x%02x%02x", 
    deviceAddress[0],deviceAddress[1],deviceAddress[2],deviceAddress[3],
    deviceAddress[4],deviceAddress[5],deviceAddress[6],deviceAddress[7]);
  return string16;
}

// function to print the temperature for a device
char* printTemperature(DeviceAddress deviceAddress)
{
  int tempC = sensors.getTempC(deviceAddress)*100;
  if (deviceAddress) {
    sprintf( string50, "<%s;%+d>", 
             printAddress(deviceAddress), 
             tempC );
  } else {
    sprintf( string50, "<%s;%+d>", 
             "noDevice",
             -127 );
  }
  return string50;
}

