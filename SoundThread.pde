class SoundThread extends Thread {
  // keep track of bpm
  int bpm = 130;

  // parent object and serial
  PApplet parent;
  Serial myPort;

  // stop thread if needed
  boolean running = true;
  boolean isActive=true;

  // serial communication buffers
  String buff = "";
  int storeX;
  int storeY;

  boolean play = false;

  SoundThread(PApplet parent) {
    // store parent
    this.parent = parent;

    // set thread priority
    setPriority(Thread.NORM_PRIORITY+2); 

    println(Serial.list());
    // start serial connection
    String portName = Serial.list()[4];
    myPort = new Serial(parent, portName, 115200);
  }

  void run() 
  {
    long rest_period = 0;

    while (this.isActive) 
    {  
      if (this.running)
      {
        /*********************************************/
        // running code
        /*********************************************/
        if (myPort.available() > 0) {
          int serial = myPort.read();
          try {    // try-catch because of transmission errors
            if (serial != 10) {
              buff += char(serial);
            } 
            else {
              // The first character tells us which axis this value is for
              char c = buff.charAt(0);
              // Remove it from the string
              buff = buff.substring(1);
              // Discard the carriage return at the end of the buffer
              buff = buff.substring(0, buff.length()-1);
              // Parse the String into an integer
              if (c == 'x')  storeX = Integer.parseInt(buff);
              if (c == 'y')  storeY = Integer.parseInt(buff);
              if (c == 'b' && Integer.parseInt(buff) == 1)  grid[7-storeX][7-storeY][activeInstrument] = true; // buttons
              if (c == 'b' && Integer.parseInt(buff) == 0)  grid[7-storeX][7-storeY][activeInstrument] = false;
              if (c == 's') {
                bpm = Integer.parseInt(buff);
                play();
              }
              if (c == 'F') { // function buttons
                function(Integer.parseInt(buff));
                function[Integer.parseInt(buff)] = true;
              }
              if (c == 'f') function[Integer.parseInt(buff)] = false;
              if (c == 'o') println("ok");
              if (c == 'D') {  // potentiometers
                midiOutput[activeInstrument].setVolume(int(120 - (Integer.parseInt(buff)*2)));
              }
              if (c == 'B') { // octave
                int newpitch = floor(Integer.parseInt(buff)/8)+2;
                if (newpitch != pitch) {
                  pitch = newpitch;
                  midiOutput[activeInstrument].setOctave(pitch);
                }
              }
              if (c == 'A') { // velocity
                midiOutput[activeInstrument].setVelocity(int(127 - (Integer.parseInt(buff)*2)));
              }
              buff = "";         // Clear the value of "buff"
            }
          }
          catch(Exception e) {
            println("no valid data");
          }
        }
      }

      /*********************************************/
      else
      {
        try 
        {
          Thread.sleep(100);
        } 
        catch(InterruptedException e) {
          println("force quit...");
        }
      }
    }
  }

  void do_stop()
  {
    this.running = false;
  }

  void do_start()
  {
    this.running = true;
  }

  int readBPM() {
    return int(60000/bpm);
  }

  // play the notes
  void play() {
    // set next position
    position = (position+1)%gridX;
    myPort.write('p');
    myPort.write(7-position);
    // play the selected notes
    for (int i = 0; i<instruments; i++) {
      for (int j = 0; j<8; j++) {
        if (midi[i] == true) {
          midiOutput[i].playNote(7-j, grid[position][j][i], i);
        }
      }
    }
  }

  // function buttons
  void function(int n) {
    if (n == 0) { // f1
      if (activeInstrument == 0) {
        activeInstrument = instruments-1;
      }
      else {
        activeInstrument = activeInstrument-1;
      }
      sendGrid(activeInstrument);
    }
    if (n == 2) { // f3
      activeInstrument = (activeInstrument+1)%instruments;
      sendGrid(activeInstrument);
    }
    if (n == 1) { // f2
      midi[activeInstrument] = !midi[activeInstrument];
    }
    if (n== 3) { // f4
      for (int x = 0; x <8; x++){
        for (int y = 0; y < 8; y++){
          grid[x][y][activeInstrument]= false;
        }
      }
      sendGrid(activeInstrument);
      midiOutput[activeInstrument].disable();
    }
  }

  // send current display to arduino
  void sendGrid(int active) {
    byte[] data = new byte[10];
    data[0]= 's';
    data[9]= '\n';
    for (int x = 0; x < 8; x++) {
      int output = 0;
      for (int y = 0; y <8; y++) {
        output = output << 1;
        if (grid[7-x][y][active] == true) {
          output |= 1;
        }
      }
      data[x+1] = byte(output);
    }
    for (int i = 0; i < data.length;i++) myPort.write(data[i]);
  }
}

