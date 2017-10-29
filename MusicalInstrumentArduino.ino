
// include library for communication with IO expander
#include <Wire.h>;
#include <inttypes.h>;

// 2-dimensional array of pixels:
boolean pixels[8][8];  
// 2-dimensional array of pressed buttons
boolean pressed[8][8];

// display bitmap
byte bitmap[8] = {
  B11111111,B11111111,B11111111,B11111111,B11111111,B11111111,B11111111,B11111111
};

// function buttons
boolean function[4];

// activate/deactivate moving line
boolean mode = true;
// current moving line position
byte pos = 0;

// potentiometers
byte pot[4];
byte prevPot[4];

// buffers
byte buffer;
String buff;

// step for changing tempo
int step = 500;
boolean stepchange = false;

void setup() {
  Wire.begin(0x20);// Initialize wire class
  sendData(0x06, 0x00); //binair 00000110, 00000000 // set all 8 ports on GP0 to output
  sendData(0x07, 0x00); //binair 00000111, 00000000 // set all 8 ports on GP1 to output

  Serial.begin(115200);
  
  // set function button pins to pull-up
  for (int i=0;i<4;i++){
    digitalWrite(10+i, HIGH);
  }

}

void loop() {

  // draw the screen:
  refreshScreen();
  //refreshButtons();
  processButtons();

  // keep track of time
  if (millis()%step > step/2 && stepchange == false){
    stepchange = true;
    // send time change
    Serial.print('s');
    Serial.println(step);
  } 
  else if (millis()%step < step/2 && stepchange == true){
    stepchange = false;
    // change step if needed
    int setstep = int(map(analogRead(2),0,1024,214.28571,1000));
    if (abs(step-setstep) > 5){
      step = setstep;
    }
  }

  // send status change of function button
  for (int i=0;i<4;i++){
    if (digitalRead(13-i) == LOW && function[i] == false){
      function[i] = true;
      Serial.print('F');
      Serial.println(i);
    }
    if (digitalRead(13-i) == HIGH && function[i] == true){
      function[i] = false;
      Serial.print('f');
      Serial.println(i);
    }
  }
  
  // send status change of potentiometers
  for (int i = 0; i<4; i++){
   pot[i] = map(analogRead(i),0,1023,0,127);
   if (pot[i] != prevPot[i]){ 
     Serial.print(char(65+i));
      Serial.println(pot[i]);
   }
   prevPot[i] = pot[i];
  }
  
}


void refreshScreen() {
  // iterate over the rows (anodes):
  byte row = 1;
  for (int thisRow = 0; thisRow < 8; thisRow++) {
    // take the row pin (anode) high:
    sendData(0x00, 0x00);
    if (pos == thisRow && mode == true){
      sendData(0x01, ~bitmap[thisRow]); 
    }
    else sendData(0x01, bitmap[thisRow]);
    sendData(0x00, row);
    for  (int thisCol = 0; thisCol <8; thisCol++){
      // detect state change of button and send
      if (digitalRead(2+thisCol)== HIGH && pressed[thisRow][thisCol] == false){
        pressed[thisRow][thisCol] = true;
        pixels[thisRow][thisCol] = !pixels[thisRow][thisCol];
        Serial.print('x');
        Serial.println(thisRow); 
        Serial.print('y');
        Serial.println(thisCol);
        Serial.print('b'); 
        Serial.println(pixels[thisRow][thisCol]); 
      }
      else if (digitalRead(2+thisCol)== LOW && pressed[thisRow][thisCol] == true){
        pressed[thisRow][thisCol] = false;
        Serial.print('x');
        Serial.println(thisRow); 
        Serial.print('y');
        Serial.println(thisCol);
        Serial.print('b'); 
        Serial.println(pixels[thisRow][thisCol]); 
      }
    }
    row = row << 1;
  }
}

void processButtons() {
  // process button changes and save to bitmap
  for (int x = 0; x < 8; x++){
    int output = 0;
    for (int y = 0; y <8; y++){
      output = output << 1;
      if(!pixels[x][y]){
        output |= 1;
      }
    }
    bitmap[x] = byte(output); 
  }
}

void sendData(uint8_t byte1, uint8_t byte2)
{
  // send pinstates of IO expander
  Wire.beginTransmission(0x20);
  Wire.write(byte1);
  Wire.write(byte2);
  Wire.endTransmission();
}

void serialEvent() {
  // recieve serial data
  while (Serial.available()>0) {
    char input = (char)Serial.read(); 
    buff += input;
    // line position change
    if (buff.length() == 2 && buff.charAt(0) == 'p'){
      pos = int(buff.charAt(1));
      buff = "";
    }
    // line mode
    if (buff.length() == 2 && buff.charAt(0) == 'm'){
      if (int(buff.charAt(1)) == 1) {
      mode = true;
      }
      else  mode = false;
      buff = "";
    }
    // display change
    if (buff.length() == 10 && buff.charAt(0) == 's'){
      for (int x = 0; x < 8; x++){
        byte input = byte(buff.charAt(x+1));
        for (int y = 0; y <8; y++){
          if (bitRead(input,y) == 1){
            pixels[x][y] = true;
          }
          else {
            pixels[x][y] = false;
          }
        }
      }
      buff = "";
    }
  }
}








