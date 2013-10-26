// BaseStation v2.0
// Toilers 2013
// Original Author: Brandon Rodriguez (brodrigu@mines.edu)

// Imports.
import processing.serial.*;

// Set the length of time to wait (in ms) before querying the next mote for data.
final int transmissionTimeout = 500;

// A list of buttons to display.
ArrayList<Button> buttons;

// A list of graphs to draw (note this is populated by the user's input of number of motes).
ArrayList<Graph> graphs;

// Set the font for the application.
PFont font;

// Set the port of the Arduino (currently set to the first port, so only have
// the Arduino plugged in and nothing else).
Serial port;

// A variable determined by user input. The boolean is used to determine when
// the user has finished submitting input.
int numberOfMotes;
boolean setMotes;

// Used to see how much time has elapsed since the last serial event.
int timeStamp;

// The boolean is set when we are expected input from the serial port, and the object is
// set before we send a command requesting data. This object is used by the serialEvent()
// function to communicate with the proper variables.
boolean hasOutput;
PrintWriter output;

// Used to print status information and mote feedback to the application.
// Access with set and get methods for ease.
String console;

// Used to determine if we are currently attempting to transmit data in the draw function.
boolean transmission;
int currentMote;

// *** IN PROGRESS ***
VScrollbar verticalScroll;

void setup() {
  size(600,675);
  
  // Instantiate global variable objects.
  buttons = new ArrayList<Button>();
  graphs = new ArrayList<Graph>();
  font = createFont("Segoe UI", 20, true);
  port = new Serial(this, Serial.list()[0], 57600);
  numberOfMotes = 0;
  setMotes = false;
  verticalScroll = new VScrollbar(width - 16, 0, height, 16, 16);
  console = "";
}

void draw() {
  textFont(font, 16);
  background(128);
  if (!setMotes) {
    fill(255);
    rect(0, 0, width, 50);
    fill(0);
    textAlign(CENTER);
    text("Please type the number of motes to communicate with,", width / 2, 25*0.8);
    text("then type 'b' to begin.", width / 2, 50*0.8);
  } else {
    if (transmission && (millis() - timeStamp) > transmissionTimeout) {
      closeFile(output);
      serialTransmit();
    }
    drawTitle();
    drawGraphs();
    drawConsole();
    drawButtons();
    verticalScroll.update();
    verticalScroll.display();
  }
}

void createLayout() {
  for (int i = 0; i < numberOfMotes; i++) {
    graphs.add(new Graph(20 + Button.bnWidth, 60 + i*Graph.gHeight));
  }
  buttons.add(new Button(10, 60 + 0*Button.bnHeight, true, "Start"));
  buttons.add(new Button(10, 70 + 1*Button.bnHeight, false, "Stop"));
  buttons.add(new Button(10, 80 + 2*Button.bnHeight, true, "Calibrate"));
  buttons.add(new Button(10, 90 + 3*Button.bnHeight, true, "Gain"));
  Button gain = buttons.get(buttons.size() - 1);
  gain.addChild("1", 1);
  gain.addChild("2", 2);
  gain.addChild("4", 3);
  gain.addChild("8", 4);
  gain.addChild("16", 5);
  gain.addChild("32", 6);
  gain.addChild("64", 7);
  gain.addChild("128", 8);
  buttons.add(new Button(10, 100 + 4*Button.bnHeight, true, "Frequency"));
  Button frequency = buttons.get(buttons.size() - 1);
  frequency.addChild("10 Samples", 1);
  frequency.addChild("100 Samples", 2);
  frequency.addChild("200 Samples", 3);
  frequency.addChild("250 Samples", 4);
  frequency.addChild("500 Samples", 5);
  buttons.add(new Button(10, 110 + 5*Button.bnHeight, true, "Precision"));
  Button precision = buttons.get(buttons.size() - 1);
  precision.addChild("16 bit", 1);
  precision.addChild("24 bit", 2);
}

void drawTitle() {
  fill(0);
  rect(0, 0, width, 50);
  fill(255);
  textAlign(CENTER);
  text("Base Station Data Collection", width / 2, 0.8 * 25);
  text(numberOfMotes + " motes", width / 2, 0.8 * 50);
}

void drawButtons() {
  Button b;
  MenuButton mb;
  textAlign(CENTER);
  for (int i = 0; i < buttons.size(); i++) {
    b = buttons.get(i);
    if(b.isActive()) {
      fill(255);
    } else {
      fill(137, 137, 137);
    }
    rect(b.getX(), b.getY(), Button.bnWidth, Button.bnHeight);
    fill(0);
    text(b.getText(), Button.bnWidth / 2 + b.getX(), b.getY() + 0.8*Button.bnHeight);
    for (int j = 0; j < b.getChildren().size(); j++) {
      mb = (MenuButton) b.getChildren().get(j);
      if (mb.isVisible()) {
        fill(0);
        rect(mb.getX() - 1, mb.getY() - 1, Button.bnWidth + 2, Button.bnHeight + 2);
        fill(255);
        rect(mb.getX(), mb.getY(), Button.bnWidth, Button.bnHeight);
        fill(0);
        text(mb.getText(), Button.bnWidth / 2 + mb.getX(), mb.getY() + 0.8*Button.bnHeight);
      }
    }
  }
}

void initButtons() {
  Button b;
  for (int i = 0; i < buttons.size(); i++) {
    b = buttons.get(i);
    if (!b.getText().equals("Stop")) {
      b.setActive(true);
    }
  }
}

void loadData() {
  Graph g;
  for (int i = 0; i < graphs.size(); i++) {
    g = graphs.get(i);
    g.loadData();
  }
}

void drawGraphs() {
  Graph g;
  for (int i = 0; i < graphs.size(); i++) {
    g = graphs.get(i);
    fill(255);
    rect(g.getX(), g.getY(), Graph.gWidth, Graph.gHeight);
    g.showData();
    g.scroll.update();
    g.scroll.display();
  }
}

void drawConsole() {
  fill(0);
  rect(0, height - 25, width, 25);
  fill(255);
  textAlign(LEFT);
  text(": " + getConsole(), 5, (height - 25) + 0.8*25);
}

void mousePressed() {
  Button b;
  for (int i = 0; i < buttons.size(); i++) {
    b = buttons.get(i);
    if (b.isClicked(mouseX, mouseY)) {
      buttonLogic(b, b.getText(), false);
      return;
    }
    if (b.isChildClicked(mouseX, mouseY)) {
      MenuButton child = b.getChildClicked(mouseX, mouseY);
      buttonLogic(child, b.getText(), true);
      return;
    }
  }
}

void keyPressed() {
  if (!setMotes) {
    if (key == 'b') {
      if (numberOfMotes > 0) {
        setMotes = true;
        createLayout();
        return;
      }
    }
    if (key >= '0' && key <= '9') {
      numberOfMotes = (numberOfMotes * 10) + Character.getNumericValue(key);
    }
  }
}

////////////////////////////////////
// Serial Functions               //
////////////////////////////////////
void buttonLogic(Button currentButton, String s, boolean isChild) {
  Button b;
  if (s.equals("Start")) {
    for (int i = 0; i < buttons.size(); i++) {
      b = buttons.get(i);
      if (b.isActive()) {
        b.setActive(false);
      }
      if (b.getText().equals("Stop")) {
        b.setActive(true);
      }
    }
    serialStart();
  } else if (s.equals("Stop")) {
    serialStop();
    for (int i = 0; i < buttons.size(); i++) {
      b = buttons.get(i);
      b.setActive(false);
    }
    serialTransmit();
  } else if (s.equals("Calibrate")) {
    serialCalibrate();
  } else if (s.equals("Gain")) {
    if (isChild) {
      MenuButton cb = (MenuButton) currentButton;
      String text = cb.getText();
      int value = cb.getValue();
      serialGain(text, value);
    }
  } else if (s.equals("Frequency")) {
    if (isChild) {
      MenuButton cb = (MenuButton) currentButton;
      String text = cb.getText();
      int value = cb.getValue();
      serialFrequency(text, value);
    }
  } else if (s.equals("Precision")) {
    if (isChild) {
      MenuButton cb = (MenuButton) currentButton;
      String text = cb.getText();
      int value = cb.getValue();
      serialPrecision(text, value);
    }
  }
}

void serialStart() {
  setConsole("Broadcasting START command");
  port.write("R");
}
void serialStop() {
  setConsole("Broadcasting STOP command");
  port.write("S");
}
void serialCalibrate() {
  setConsole("Broadcasting CALIBRATE command");
  port.write("C");
}
void serialGain(String text, int value) {
  if (value > 0 && value < 9) {
    setConsole("Broadcasting GAIN. Setting to " + text);
    port.write("G" + value);
  } else {
    setConsole("Error broadcasting GAIN command");
  }
}
void serialFrequency(String text, int value) {
  if (value > 0 && value < 6) {
    setConsole("Broadcasting FREQUENCY. Setting to " + text);
    port.write("F" + value);
  } else {
    setConsole("Error broadcasting FREQUENCY command");
  }
}
void serialPrecision(String text, int value) {
  if (value > 0 && value < 3) {
    setConsole("Broadcasting PRECISION. Setting to " + text);
    port.write("P" + value);
  } else {
    setConsole("Error broadcasting PRECISION command");
  }
}
void serialTransmit() {
  if (currentMote < numberOfMotes) {
    transmission = true;
  } else {
    transmission = false;
    currentMote = 0;
    loadData();
    initButtons();
    return;
  }
  currentMote++;
  int year, month, day, hour, minute, second;
  String filename;
  Graph g;
  setConsole("Requesting transmission from mote " + currentMote);
  year = year();
  month = month();
  day = day();
  hour = hour();
  minute = minute();
  second = second();
  filename = currentMote + "_" + year + "-" + month + "-" + day + " " + hour + minute + second + ".txt";
  g = graphs.get(currentMote - 1);
  g.filename = filename;
  output = openFile(filename);
  timeStamp = millis();
  port.write("T" + currentMote);
}
void serialEvent(Serial p) {
  timeStamp = millis();
  byte[] bytes = new byte[4];
  if (hasOutput) {
    output.println(bytes);
  }
}

// File Methods.
PrintWriter openFile(String filename) {
  hasOutput = true;
  return createWriter(filename);
}
void closeFile(PrintWriter fileDescriptor) {
  hasOutput = false;
  fileDescriptor.flush();
  fileDescriptor.close();
}
void setConsole(String s) {
  console = s;
  drawConsole();
}
String getConsole() {
  return console;
}
