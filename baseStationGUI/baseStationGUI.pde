// Import the Serial class for use with radio.
import processing.serial.*;
import controlP5.*;

// Hard-coded values of button locations.
// int[] bnName = {xPos, yPos};
int[] bnStart = {50, 50};
int[] bnEnd = {175, 50};
int[] bnTransmit = {175, 100};
int[] bnCalibrate = {300, 100};
int[] bnGain = {50, 150};
DropdownList bnGain1;
int[] bnFrequency = {175, 150};
int[] bnGraph = {300, 150};
int bnHeight, bnWidth;

// Variables relating to the text for some of the buttons.
int gainValue, frequencyValue;
int[] frequencyRate = {10, 100, 200, 250, 500};
String gainText, frequencyText;
boolean drawGraph;
HScrollbar hs1;
ArrayList<Integer> scaledData;

// Create environment variables to control font,
// serial port, file I/O, and the number of motes (hard-coded
// for now).
PFont f;
Serial port;
int motes;
PrintWriter output;
boolean fileOpen;
BufferedReader input;
int timeStampLastData;
String console;
ControlP5 cp5;

/**
 * Instantiate some of the global variables.
 * Set window size, font family, and default values for some text fields.
 * 
 */
void setup() {
  size(450, 410);
  f = createFont("Segoe UI", 20, true);
  port = new Serial(this, Serial.list()[0], 57600);
  console = "";
  scaledData = new ArrayList<Integer>();
  hs1 = new HScrollbar(0, 381, width, 16, 16);
  
  /*cp5 = new ControlP5(this);
  bnGain1 = cp5.addDropdownList("Gain").setPosition(25,100).setSize(bnWidth, bnHeight);
  bnGain1.addItem("1", 1);
  bnGain1.addItem("2", 2);
  bnGain1.addItem("3", 4);*/
  
  // Set Precision button between 16 and 24 bits.
  // PL for 16 and PH for 24 (low and high)

  gainValue = 1;
  gainText = "Gain 1.0";
  
  frequencyValue = 1;
  frequencyText = "Frequency 10";
  
  bnHeight = 25;
  bnWidth = 120;
  
  motes = 3;
}

/**
 * Draw the buttons and room for a graph of data.
 * 
 * 
 */
void draw() {
  background(128);
  textFont(f, 16);
  textAlign(CENTER);
  
  // Header.
  fill(0);
  rect(0, 0, width, 0.8*bnHeight + 15);
  fill(255);
  text("Data Collector", width/2, 25);
  
  // Button rectangles.
  fill(255);
  rect(bnStart[0], bnStart[1], bnWidth, bnHeight);
  rect(bnEnd[0], bnEnd[1], bnWidth, bnHeight);
  rect(bnTransmit[0], bnTransmit[1], bnWidth, bnHeight);
  rect(bnCalibrate[0], bnCalibrate[1], bnWidth, bnHeight);
  rect(bnGain[0], bnGain[1], bnWidth, bnHeight);
  rect(bnFrequency[0], bnFrequency[1], bnWidth, bnHeight);
  rect(bnGraph[0], bnGraph[1], bnWidth, bnHeight);
  rect(0, 189, width-1, 200);
  
  fill(240);
  rect(0, 389, 450, 20);
  fill(255,0,0);
  for (int i = 0; i < scaledData.size(); i++) {
    rect(i - (round(hs1.getPos())*(scaledData.size()-450)/450), 389, 1, (-1)*scaledData.get(i));
  }
  hs1.update();
  hs1.display();
  
  // Button text.
  fill(0);
  text("Start", bnWidth/2 + bnStart[0], bnStart[1] + 0.8*bnHeight);
  text("Stop", bnWidth/2 + bnEnd[0], bnEnd[1] + 0.8*bnHeight);
  text("Transmit", bnWidth/2 + bnTransmit[0], bnTransmit[1] + 0.8*bnHeight);
  text("Calibrate", bnWidth/2 + bnCalibrate[0], bnCalibrate[1] + 0.8*bnHeight);
  text(gainText, bnWidth/2 + bnGain[0], bnGain[1] + 0.8*bnHeight);
  text(frequencyText, bnWidth/2 + bnFrequency[0], bnFrequency[1] + 0.8*bnHeight);
  text("Graph Data", bnWidth/2 + bnGraph[0], bnGraph[1] + 0.8*bnHeight);
  
  textAlign(LEFT);
  text(": " + console, 5, 405);

}

/**
 * Depending on where the user clicks, check if any are over buttons.
 * Call the corresponding button's function.
 */
void mousePressed() {
  if (overRect(bnStart)) {
    beginCollection();
  } else if (overRect(bnEnd)) {
    endCollection();
  } else if (overRect(bnTransmit)) {
    requestTransmissions();
  } else if (overRect(bnCalibrate)) {
    calibrate();
  } else if (overRect(bnGain)) {
    changeGain();
  } else if (overRect(bnFrequency)) {
    changeFrequency();
  } else if (overRect(bnGraph)) {
    graphData();
  }
}

/**
 * Determine if a mouseclick is within a rectangle.
 * Args: pos: the upper left corner of the rectangle.
 * Returns: true if inside the rectangle, false otherwise.
 */
boolean overRect(int[] pos) {
  if (mouseX >= pos[0] && mouseX <= pos[0]+bnWidth &&
      mouseY >= pos[1] && mouseY <= pos[1]+bnHeight) {
    return true;
  } else {
    return false;
  }
}

/**
 * Broadcast to the motes to begin data collection. If collection is in progress,
 * it will be restarted.
 */
void beginCollection() {
  // Start collecting.
  console = "Broadcasting START command.";
  port.write("R");
}

/**
 * Broadcast to the motes to stop data collection. If no collection is in progress,
 * nothing will happen.
 */
void endCollection() {
  // Stop collecting.
  console = "Broadcasting STOP command.";
  port.write("S");
}

/**
 * Broadcast to motes to calibrate.
 * 
 */
void calibrate() {
  console = "Broadcasting CALIBRATE command.";
  port.write("C");
}

/**
 * Broadcast to motes to change the gain.
 * Clicking the Gain button cycles through possible gain values.
 */
void changeGain() {
  gainValue += 1;
  gainValue = gainValue % 9;
  if (gainValue == 0) {
    gainValue = 1;
  }
  
  float gainRate = pow(2, (gainValue - 1));
  gainText = "Gain " + gainRate;
  
  console = "Broadcasting G" + gainValue + ".";
  port.write("G" + gainValue);
}

/**
 * Broadcast to the motes to change the frequency.
 * Clicking the button will cycle through possible frequencies.
 */
void changeFrequency() {
  frequencyValue += 1;
  frequencyValue = frequencyValue % 6;
  if (frequencyValue == 0) {
    frequencyValue = 1;
  }
  
  frequencyText = "Frequency " + frequencyRate[frequencyValue - 1];
  
  console = "Broadcasting F" + frequencyValue + ".";
  port.write("F" + frequencyValue);
}

/**
 * Ask the motes (round robin = one-by-one) to transmit their data.
 * Waits for 100 ms of silence before requesting from the next mote.
 */
void requestTransmissions() {
  // Assume we know all the motes. Then loop through these motes.
  for (int i = 1; i < (motes+1); i++) {
    // Create a nice file to write data to.
    output = createWriter(i + "_data.txt");
    fileOpen = true;
    
    // Send the command to get feedback.
    console = "Asking mote " + i + " for transmission data.";
    port.write("T" + i);
    
    timeStampLastData = millis();
    // Give the mote time to receive and start sending.
    while ((millis() - timeStampLastData) < 100) {
      // Keep the loop from requesting another mote
      // until we haven't heard anything for 100 ms.
    }
    
    fileOpen = false;
    output.flush();
    output.close();
  }
}

/**
 * Read data from the files. Then, graph it.
 * **WORK IN PROGRESS**
 * 
 */
void graphData() {
  scaledData = new ArrayList<Integer>();
  String[] lines = loadStrings("1_data.txt");
  int max = 0;
  // Determine the largest number to make the scale.
  for (int i = 0; i < lines.length; i++) {
    if (Integer.parseInt(lines[i]) > max) {
      max = Integer.parseInt(lines[i]);
    }
  }
  drawGraph = true;
  
  double scale = 200.0/max;
  println("Scale " + scale);
  for (int i = 0; i < lines.length; i++) {
    scaledData.add((int)Math.round(scale*Integer.parseInt(lines[i])));
    //println(scaledData.get(i));
  }
}

/**
 * Handles incoming serial data from our radio.
 * If we are receving a transmission, an open file handler should be used to write
 * data to file.
 */
void serialEvent(Serial myPort) {
try {
  timeStampLastData = millis();
  String inString = myPort.readStringUntil('\n');
   if (inString != null) {
    inString = trim(inString);
    console = inString;
//println(inString);
    if (fileOpen) {
      output.println(inString);
    }
   }
} catch (Exception e) {
   println(e); 
}
    
}

