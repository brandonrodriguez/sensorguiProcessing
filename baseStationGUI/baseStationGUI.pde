import processing.serial.*;

int[] bnStart = {50, 50};
int[] bnEnd = {175, 50};
int[] bnRestart = {300, 50};
int[] bnSynchronize = {50, 100};
int[] bnTransmit = {175, 100};
int[] bnCalibrate = {300, 100};
int[] bnGain = {50, 150};
int[] bnFrequency = {175, 150};
int gainValue, frequencyValue;
int[] frequencyRate = {10, 100, 200, 250, 500};
String gainText, frequencyText;
int bnHeight, bnWidth;
PFont f;
Serial port;
int motes;
PrintWriter output;

void setup() {
  size(450, 390);
  f = createFont("Segoe UI", 20, true);
  
  // Serial(parent, String portName, rate);
  port = new Serial(this, Serial.list()[0], 57600);
  
  gainValue = 1;
  gainText = "Gain 1.0";
  
  frequencyValue = 1;
  frequencyText = "Frequency 10";
  
  bnHeight = 25;
  bnWidth = 120;
  
  motes = 1;
}

void draw() {
  textFont(f, 16);
  textAlign(CENTER);
  
  fill(0);
  rect(0, 0, width, 0.8*bnHeight + 15);
  fill(255);
  text("Data Collector", width/2, 25);
  
  fill(255);
  rect(bnStart[0], bnStart[1], bnWidth, bnHeight);
  rect(bnEnd[0], bnEnd[1], bnWidth, bnHeight);
  rect(bnRestart[0], bnRestart[1], bnWidth, bnHeight);
  rect(bnSynchronize[0], bnSynchronize[1], bnWidth, bnHeight);
  rect(bnTransmit[0], bnTransmit[1], bnWidth, bnHeight);
  rect(bnCalibrate[0], bnCalibrate[1], bnWidth, bnHeight);
  rect(bnGain[0], bnGain[1], bnWidth, bnHeight);
  rect(bnFrequency[0], bnFrequency[1], bnWidth, bnHeight);
  rect(0, 188, width, 198);
  
  fill(0);
  text("Start", bnWidth/2 + bnStart[0], bnStart[1] + 0.8*bnHeight);
  text("End", bnWidth/2 + bnEnd[0], bnEnd[1] + 0.8*bnHeight);
  text("Restart", bnWidth/2 + bnRestart[0], bnRestart[1] + 0.8*bnHeight);
  text("Synchronize", bnWidth/2 + bnSynchronize[0], bnSynchronize[1] + 0.8*bnHeight);
  text("Transmit", bnWidth/2 + bnTransmit[0], bnTransmit[1] + 0.8*bnHeight);
  text("Calibrate", bnWidth/2 + bnCalibrate[0], bnCalibrate[1] + 0.8*bnHeight);
  text(gainText, bnWidth/2 + bnGain[0], bnGain[1] + 0.8*bnHeight);
  text(frequencyText, bnWidth/2 + bnFrequency[0], bnFrequency[1] + 0.8*bnHeight);
  

}

void mousePressed() {
  if (overRect(bnStart)) {
    beginCollection();
  } else if (overRect(bnEnd)) {
    endCollection();
  } else if (overRect(bnRestart)) {
    restartCollection();
  } else if (overRect(bnSynchronize)) {
    synchronizeADC();
  } else if (overRect(bnTransmit)) {
    requestTransmissions();
  } else if (overRect(bnCalibrate)) {
    calibrate();
  } else if (overRect(bnGain)) {
    changeGain();
  } else if (overRect(bnFrequency)) {
    changeFrequency();
  }
  // Add logic here!
}

boolean overRect(int[] pos) {
  if (mouseX >= pos[0] && mouseX <= pos[0]+bnWidth &&
      mouseY >= pos[1] && mouseY <= pos[1]+bnHeight) {
    return true;
  } else {
    return false;
  }
}

void beginCollection() {
  // Start collecting.
  println("R");
  port.write("R");
}

void endCollection() {
  // Stop collecting.
  println("S");
  port.write("S");
}

void restartCollection() {
  // Stop data collection, start without transmitting?
  println("R");
  port.write("R");
}

void synchronizeADC() {
  println("Y");
  port.write("Y");
}

void calibrate() {
  println("C");
  port.write("C");
}

void changeGain() {
  gainValue += 1;
  gainValue = gainValue % 9;
  if (gainValue == 0) {
    gainValue = 1;
  }
  
  float gainRate = pow(2, (gainValue - 1));
  gainText = "Gain " + gainRate;
  
  println("G" + gainValue);
  port.write("G" + gainValue);
}

void changeFrequency() {
  frequencyValue += 1;
  frequencyValue = frequencyValue % 6;
  if (frequencyValue == 0) {
    frequencyValue = 1;
  }
  
  frequencyText = "Frequency " + frequencyRate[frequencyValue - 1];
  
  println("F" + frequencyValue);
  port.write("F" + frequencyValue);
}

void requestTransmissions() {
  // Assume we know all the motes. Then loop through these motes.
  for (int i = 1; i < (motes+1); i++) {
    // Create a nice file to write data to.
    output = createWriter(i + "_data.txt");
    println("T" + i);
    
    // Send the command to get feedback.
    port.write("T" + i);
    
    // Give the mote time to receive and start sending.
    delay(200);
    
    // Ghetto way to keep the basestation from contacting another mote.
    while(port.available() > 0) {
      // wait (later calculate time to wait empirically)
    }
    
    // Rewrite to use milli and keep track of if any data is coming in while we wait for 100ms,
    // instead of just sleeping. If we delay, do we lose data, too?
    
    
    // We're out of bytes. Let's wait 100ms to see if any more come in.
    delay(100);
    // If more bytes came in, wait another second to accomodate slackers.
    if (port.available() > 0) {
      delay(1000);
    }
    
    // Close out the file.
    output.flush();
    output.close();
  }
}

void serialEvent(Serial myPort) {
  String inString = myPort.readStringUntil('\n');
   if (inString != null) {
    inString = trim(inString);
    output.println(inString);
    println(inString);
   }
    
}

