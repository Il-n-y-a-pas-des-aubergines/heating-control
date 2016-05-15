#include <OneWire.h>
#include <DallasTemperature.h>


// im PC Terminal ausgeben mit:
// $ cat /dev/ttyACM0

// Wertebereich der Sensoren:
// -127..+85 °C
// treten gelegentlcih beim ein- und ausstecken auf.

// Data wire is plugged into pin 2 on the Arduino
#define ONE_WIRE_BUS 2

// Setup a oneWire instance to communicate with any OneWire devices (not just Maxim/Dallas temperature ICs)
OneWire oneWire(ONE_WIRE_BUS);

// Pass our oneWire reference to Dallas Temperature. 
DallasTemperature sensors(&oneWire);

// arrays to hold device addresses
DeviceAddress sensor_adr[20];

// beliebige Strings
char string[300];
// in Unterfunktionen
char string50[51];
// Geräteadressen
char string16[17];


// ----------------------------------
void setup(void)
{
  // c.mer
  Serial.flush();
  
  // start serial port
  Serial.begin(9600);
  Serial.println("------------------------------------------");
  Serial.println("Dallas Temperature IC Control Library Demo");

  // Start up the library
  sensors.begin(); // IC Default 9 bit. If you have troubles consider upping it 12. 
                   // Ups the delay giving the IC more time to process the temperature measurement
  delay(1000);        // delay in between reads for stability

  // locate devices on the bus
  sprintf(string, "Habe %u Sensoren gefunden.\n", sensors.getDeviceCount());
  Serial.print( string );
  
  for (int i = 0; i < sensors.getDeviceCount(); i++) {
    if (sensors.getAddress(sensor_adr[i], i)) {
      sprintf(string, "Adresse von Sensor %u: %s\n", i, printAddress(sensor_adr[i]));
      Serial.print( string );
    } else {
      sprintf(string, "Unable to find address for Device %u\n", i);
      Serial.print( string );
    }
  }
  Serial.println();
}


// ----------------------------------
void loop(void)
{ 
  DeviceAddress addr;
  
  sensors.begin(); // IC Default 9 bit. If you have troubles consider upping it 12. 
  delay(50);       // delay in between reads for stability

  sensors.requestTemperatures(); // Send the command to get temperatures
  
  // Schleife, die die Werte aller gefundenen Sensoren ausgibt
  Serial.print("[");
  for (int i = 0; i < sensors.getDeviceCount(); i++) {
    sensors.getAddress(addr, i);
    Serial.print( printTemperature(addr) );
  }
  Serial.println("]");
  
  
  // call sensors.requestTemperatures() to issue a global temperature 
  // request to all devices on the bus
  //Serial.print("Requesting temperatures...");
  //sensors.requestTemperatures(); // Send the command to get temperatures
  //Serial.print("DONE - ");
  
  //Serial.print("Temperature for Device 0 is: ");
  //Serial.print(sensors.getTempCByIndex(0)); 
  // Why "byIndex"? You can have more than one IC on the same bus. 0 refers to the first IC on the wire
  //Serial.print(" - Temperature for Device 1 is: ");
  //Serial.println(sensors.getTempCByIndex(1)); 
  
  // c.mer
  Serial.flush();
  delay(1000);        // delay in between reads for stability
  
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
  // ! wg. sprintf bug: int, * 100 !
  //float tempC = sensors.getTempC(deviceAddress);
  int tempC = sensors.getTempC(deviceAddress)*100;
  if (deviceAddress) {
    sprintf( string50, "<%s;%+d>", 
             printAddress(deviceAddress), 
             tempC );
  } else {
    sprintf( string50, "<%s;%+d>", 
             "noDevice",
             0 );
  }
  return string50;
  //Serial.print("Temp C: ");
  //Serial.print(tempC);
  //Serial.print(" Temp F: ");
  //Serial.print(DallasTemperature::toFahrenheit(tempC));
}

