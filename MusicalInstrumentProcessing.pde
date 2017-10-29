
//Import Exploding Art's SoundCipher library
import arb.soundcipher.*;

//Create new SoundCipher and SoundCipherScore instance.
SoundCipher sc = new SoundCipher(this);
SCScore score = new SCScore();

//Make separate thread for precise timing.
SoundThread sound;

//Make instruments and generators and midi outputs.
int instruments = 16;
Midi[] midiOutput = new Midi[instruments];

//Make serial connection.
import processing.serial.*;

//Import Java Map function and DataConverter for Base64 conversion.
import java.util.Map;
import javax.xml.bind.DatatypeConverter;

//Array of all characters used in the Base64 charset.
char[] b64Array = {
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '/'
}; 

//Create new HashMap instance for the Base64 map.
HashMap<Character, Integer> b64Map = new HashMap<Character, Integer>();

//Set grid size.
int gridX = 8;
int gridY = 8;
//Keep track of current play position.
int position = 0;

boolean[][][] grid = new boolean[gridX][gridY][instruments];
boolean[] function = new boolean[instruments];

//Store current instrument.
int activeInstrument = 0;

//Store current output.
boolean[] midi = new boolean[instruments];

// pitch, modulation.
int pitch;
int pitchBend;

//Make font.
PFont font;

//Make space for UI.
int uiOffset = 200;

void setup() {
  size(1000, 800);

  //Make generator objects and midi objects. turn on all inputs
  for (int i = 0; i<instruments; i++) {
    midiOutput[i] = new Midi(i);
    midi[i] = true;
  }

  //Set font, uncomment following lines to display available fonts.
  font = createFont("Arial Black", 16);
  textFont(font);

  //Start sound thread.
  sound = new SoundThread(this);
  sound.setPriority(Thread.NORM_PRIORITY+2); 
  sound.start();
}

void draw() {
  background(255);

  // normal display mode
  if (key != 'a' && key != 'h') {
    // draw grid
    for (int x = 0; x<gridX; x++) {
      // highlight current position
      if (position == x) {
        stroke(255, 0, 0);
      }
      else {
        stroke(0);
      }
      for (int y = 0; y<gridY; y++) {
        // fill selected fields
        if (grid[x][y][activeInstrument] == true) {
          fill(255, 200, 200);
        } 
        else { 
          fill(255, 255, 255, 0);
        }
        // draw the rectangle
        rect(int((width-uiOffset)/gridX)*x, int(height/gridY)*y, int((width-uiOffset)/gridX)-1, int(height/gridY)-1);
      }
    }
  }


  // display active instrument
  fill(255, 0, 0);
  textSize(20);
  text("Channel " + (activeInstrument + 1), width-150, height-100);

  // display current tempo
  textSize(20);
  text("BPM "+ sound.readBPM(), width-150, height-50);
  
  // display current tempo
  textSize(20);
  text("Octave C"+ midiOutput[activeInstrument].readOctave(), width-150, height-150);
  
  // display volume
  fill(255);
  stroke(0);
  rect(width-105,150,10,-120);
  fill(0);
  textSize(10);
  text("Volume", width-120,165);
  fill(255,0,0);
  rect(width-105,150,10,-midiOutput[activeInstrument].readVolume());
  
  // display velocity
  fill(255);
  stroke(0);
  rect(width-105,350,10,-120);
  fill(0);
  textSize(10);
  text("Velocity", width-125,365);
  fill(255,0,0);
  rect(width-105,350,10,-midiOutput[activeInstrument].readVelocity()+9);
  
}

void mousePressed() {
  // detect mouseklick on grid and store in normal mode
  if (mouseX<= width-uiOffset && key != 'a' && key != 's') {
    int tempx = floor(mouseX/( (width-uiOffset)/gridX));
    int tempy = floor(mouseY/( (height)/gridY));

    toggleNote(tempx, tempy, activeInstrument);
  }
}

void keyPressed() {
  //Debugging: Manual changing of values for debugging purposes.
//  if (key == ',') {
//    midiOutput[activeInstrument].setOctave(-1);
//  }
//  if (key == '.') {
//    midiOutput[activeInstrument].setOctave(1);
//  }
  
  //Load text string or text file.
  if (key == 'l') {
    //textToNote("Hello World");
    String[] lines = loadStrings("http://google.com"); //Load text file for the textToNote function.
    textToNote(lines[0]);
    
    sound.sendGrid(activeInstrument);
  }
}

//Stop the sketch appropriately.
public void stop() {
  if (sound!=null) sound.isActive=false;
  sound.do_stop();
  
  for (int i = 0; i < instruments; i++) {
    midiOutput[i].disable();
  }

  super.stop();
}

void play() {
  //Set next position.
  position = (position+1)%gridX;
  //Play the selected notes.
  for (int i = 0; i<instruments; i++) {
    for (int j = 0; j<8; j++) {
      if (midi[i] == true) {
        midiOutput[i].playNote(7-j, grid[position][j][i], i);
      }
    }
  }
}

//Toggle a note in the grid on the specified instrument.
void toggleNote(int x, int y, int instrument) {
  grid[x][y][instrument] = !grid[x][y][instrument];
}

//Set a note to ON in the grid on the specified instrument.
void onNote(int x, int y, int instrument) {
  grid[x][y][instrument] = true;
}

//Set a note to Off in the grid on the specified instrument.
void offNote(int x, int y, int instrument) {
  grid[x][y][instrument] = false;
}

void textToNote(String text) {
  //Convert a text string to a Base64 string
  String b64 = DatatypeConverter.printBase64Binary(text.getBytes());

  char[] b64Char = new char[b64.length()];

  //Create an array the length of the base64 string with a length maximum of 64 characters.
  int[] posArray = new int[(b64.length() < 64) ? b64.length() : 64]; 

  //Convert the character array into an character map.
  for (int i = 0; i < b64Array.length; i++) b64Map.put(b64Array[i], i);

  //Add the characters from the Base64 string to a position array.
  for (int i = 0; i < ((b64.length() < 64) ? b64.length() : 64); i++) if (b64.charAt(i) != '=') posArray[i] = b64Map.get(b64.charAt(i));

  //Set selected notes inside the array to ON.
  for (int i = 0; i < posArray.length; i++) onNote((posArray[i] - (posArray[i] % 8)) / 8, posArray[i] % 8, activeInstrument);
}

