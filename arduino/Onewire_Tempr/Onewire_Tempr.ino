#include <OneWire.h>
#include <DallasTemperature.h>

// im PC Terminal ausgeben mit:
// $ cat /dev/ttyACM0

int debug = 0;
// 0=none, 1=debug

///////////////////////////////////
// Dallas DS1820 Temperatursensoren
// Wertebereich der Sensoren: -55..+125 °C
// Genauigkeit +/- 0,5 °C im Bereich: -10..85 °C
// power-on-reset value: 85 °C
// Fehlerwert: -127 °C
// treten gelegentlich beim ein- und ausstecken auf.

// Data wire is plugged into pin 2 on the Arduino
#define ONE_WIRE_BUS 2

// Setup a oneWire instance to communicate with any OneWire devices (not just Maxim/Dallas temperature ICs)
OneWire oneWire(ONE_WIRE_BUS);

// Pass our oneWire reference to Dallas Temperature. 
DallasTemperature sensors(&oneWire);

// arrays to hold device addresses
DeviceAddress sensor_adr[20];

// in Unterfunktionen
char string50[51];
// Geräteadressen
char string16[17];

// wg. bug; max. Wert, bei dem delay() funktioniert
const unsigned long max_delay_30sec = 30*1000; 

// Verzögerung zwischen 2 Messungen
const unsigned long loop_delay_min = 10;

// ----------------------------------
void setup(void)
{
  // start serial port
  Serial.begin(9600);
  Serial.println("[InitArduino]");
}


// ----------------------------------
void loop(void)
{ 
  // Sensoren in jedem Durchlauf initialisieren, um neue/entfernte Sensoren zu erkennen
  sensors.begin(); // IC Default 9 bit. If you have troubles consider upping it 12. 
  delay(100);       // delay in between reads for stability

  // Werte auslesen
  sensors.requestTemperatures(); // Send the command to get temperatures
  
  // Schleife, die die Werte aller gefundenen Sensoren ausgibt
  // string hat das Format '[<id;value>...]', 
  // 'id' ist die physische Sensor ID, 
  // 'value' 100*Messwert (weil keine floats übergeben werden können)
  DeviceAddress addr;
  String string = "[";
  for (int i = 0; i < sensors.getDeviceCount(); i++) {
    sensors.getAddress(addr, i);
    string = string + printTemperature(addr);
  }
  string = string + "]";
  
  // Rückgabe string seriell ausgeben
  Serial.println(string);
  
  // bug fix: delay() funktioniert nur bis 30sec.
  // max_delay_30sec*2*loop_delay_min = loop_delay_min Minuten
  for (int i = 0; i < loop_delay_min*2; i++) {
    delay(max_delay_30sec);  
    if (debug==1) {
      string = "in delay loop";
      string = string + ", " + printMinutes();
      string = string + ", " + printSeconds();
      Serial.println( string );
    }
  }
  
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
  // bug fix; Temperatur*100 wird als int übergeben, weil float nicht möglich ist
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

// debug; Sekunden seit Start ausgeben
// bug fix: Überlauf bei 32767 - deshalb Sekunde / Minuten ausgeben
// bug fix: bei 
//     sprintf( string50, "Seconds: %d, Minutes: %d", currentSeconds, currentMinutes );
//   sind die Minuten immer 0, also 2 Funktionen
char* printMinutes()
{
  unsigned long currentMinutes = millis()/60000;
  sprintf( string50, "Minutes: %d", currentMinutes );
  return string50;
}
char* printSeconds()
{
  unsigned long currentSeconds = millis()/1000;
  sprintf( string50, "Seconds: %d", currentSeconds );
  return string50;
}
