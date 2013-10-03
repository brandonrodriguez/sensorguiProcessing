import processing.serial.*;

int[] bnStart = {50, 50};
int[] bnEnd = {175, 50};
int[] bnRestart = {300, 50};
int[] bnSynchronize = {50, 100};
int[] bnTransmit = {175, 100};
int[] bnCalibrate = {300, 100};
int[] bnGain = {50, 150};
int gainValue;
String gainText;
int bnHeight, bnWidth;
PFont f;
Serial port;

void setup() {
  size(450, 190);
  f = createFont("Segoe UI", 20, true);
  
  // Serial(parent, String portName, rate);
  port = new Serial(this, Serial.list()[0], 57600);
  
  gainValue = 1;
  gainText = "Gain 1";
  
  bnHeight = 25;
  bnWidth = 100;
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
  
  fill(0);
  text("Start", bnWidth/2 + bnStart[0], bnStart[1] + 0.8*bnHeight);
  text("End", bnWidth/2 + bnEnd[0], bnEnd[1] + 0.8*bnHeight);
  text("Restart", bnWidth/2 + bnRestart[0], bnRestart[1] + 0.8*bnHeight);
  text("Synchronize", bnWidth/2 + bnSynchronize[0], bnSynchronize[1] + 0.8*bnHeight);
  text("Transmit", bnWidth/2 + bnTransmit[0], bnTransmit[1] + 0.8*bnHeight);
  text("Calibrate", bnWidth/2 + bnCalibrate[0], bnCalibrate[1] + 0.8*bnHeight);
  text(gainText, bnWidth/2 + bnGain[0], bnGain[1] + 0.8*bnHeight);
  

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
  println("O");
  port.write("O");
}

void restartCollection() {
  // Stop data collection, start without transmitting?
  println("R");
  port.write("R");
}

void synchronizeADC() {
  println("S");
  port.write("S");
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

void requestTransmissions() {
  // Add round robin logic here.
  println("T");
  port.write("T");
  //serialEvent();
  
}

void serialEvent(Serial myPort) {
  String inString = myPort.readStringUntil('\n');
   if (inString != null) {
    inString = trim(inString);
    println(inString);
   }
    
}

