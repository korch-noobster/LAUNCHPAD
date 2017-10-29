class Midi {
  int channel = 0;
  int octave = 36;
  int velocity = 127;
  int volume = 120;
  int prevVelocity;

  int i = 0;

  boolean[] activeNote = new boolean[8];

  //Note scheme
  int[] note = {
    0, 2, 4, 5, 7, 9, 11, 12
  };

  //Different notes for drum like instruments (channel 13 - 16) these are non harmonic instruments.
  int[] drum = {
    36, 38, 39, 42, 46, 49, 51, 56
  };

  //Initialize  midi channel.
  Midi(int channel) {
    this.channel = channel;
  }

  void playNote(int pitch, boolean state, int instrument) {
    //If current note has to be played and is not active.
    if (state == true && activeNote[pitch] == false) {
      //Send ON, channel, pitch and velocity to midi, change pitch to fixed notes if current instrument is a drum.
      sc.sendMidi(sc.NOTE_ON, channel, ((instrument <= 12) ? octave+note[pitch] : drum[pitch]), velocity);
      activeNote[pitch] = true;
    }
    //If current does not have to be played but is still active.
    else if (state == false && activeNote[pitch] == true) {
      //Send OFF, channel, pitch and velocity to midi, change pitch to fixed notes if current instrument is a drum.
      sc.sendMidi(sc.NOTE_OFF, channel, ((instrument <= 12) ? octave+note[pitch] : drum[pitch]), velocity);
      activeNote[pitch] = false;
    }
    //If current has to be played and also is still active
    else if (state == true && activeNote[pitch] == true) {
      //Send first an OFF message and then an ON message.
      sc.sendMidi(sc.NOTE_OFF, channel, ((instrument <= 12) ? octave+note[pitch] : drum[pitch]), velocity);
      sc.sendMidi(sc.NOTE_ON, channel, ((instrument <= 12) ? octave+note[pitch] : drum[pitch]), velocity);
      activeNote[pitch] = true;
    }
  }

  //Todo: Save music to midi.
  void saveNote(int pitch, boolean state) {
    if (state == true && activeNote[pitch] == false) {      
      score.addNote(i, channel, channel, pitch, random(60, 100), 1, 1, 1);
      i++;
    }
  }

  //Set octave of the current instrument
  void setOctave(int input) {
    int prevOctave = octave;
    octave = 12*input;
    for (int i = 0; i <8; i++) {
      if (activeNote[i] == true) {
        sc.sendMidi(sc.NOTE_OFF, channel, prevOctave+note[i], velocity);
        sc.sendMidi(sc.NOTE_ON, channel, octave+note[i], velocity);
      }
    }
  }
  
  int readOctave() {
    return (octave/12) - 1;
  }

  //Turn all active notes off
  void disable() {
    sc.stop();
  }

  //Set volume of instrument.
  void setVolume(int input) {
    if (abs(volume - input) > 5) {
      sc.sendMidi(sc.CONTROL_CHANGE, channel, 7, input);
      volume = input;
    }
  }
  
  int readVolume() {
   return volume; 
  }

  //Change pitch of the instrument.
  void setVelocity(int input) {
    if (abs(prevVelocity - input) > 5) {
      velocity = input;
      prevVelocity = input;
    } 
  }
  
  int readVelocity() {
   return velocity; 
  }
}

