import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import processing.serial.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class baseStationGUI2 extends PApplet {

// BaseStation v2.0
// Toilers 2013
// Original Author: Brandon Rodriguez (brodrigu@mines.edu)

// Imports.


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

public void setup() {
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

public void draw() {
  textFont(font, 16);
  background(128);
  if (!setMotes) {
    fill(255);
    rect(0, 0, width, 50);
    fill(0);
    textAlign(CENTER);
    text("Please type the number of motes to communicate with,", width / 2, 25*0.8f);
    text("then type 'b' to begin.", width / 2, 50*0.8f);
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

public void createLayout() {
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

public void drawTitle() {
  fill(0);
  rect(0, 0, width, 50);
  fill(255);
  textAlign(CENTER);
  text("Base Station Data Collection", width / 2, 0.8f * 25);
  text(numberOfMotes + " motes", width / 2, 0.8f * 50);
}

public void drawButtons() {
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
    text(b.getText(), Button.bnWidth / 2 + b.getX(), b.getY() + 0.8f*Button.bnHeight);
    for (int j = 0; j < b.getChildren().size(); j++) {
      mb = (MenuButton) b.getChildren().get(j);
      if (mb.isVisible()) {
        fill(0);
        rect(mb.getX() - 1, mb.getY() - 1, Button.bnWidth + 2, Button.bnHeight + 2);
        fill(255);
        rect(mb.getX(), mb.getY(), Button.bnWidth, Button.bnHeight);
        fill(0);
        text(mb.getText(), Button.bnWidth / 2 + mb.getX(), mb.getY() + 0.8f*Button.bnHeight);
      }
    }
  }
}

public void initButtons() {
  Button b;
  for (int i = 0; i < buttons.size(); i++) {
    b = buttons.get(i);
    if (!b.getText().equals("Stop")) {
      b.setActive(true);
    }
  }
}

public void loadData() {
  Graph g;
  for (int i = 0; i < graphs.size(); i++) {
    g = graphs.get(i);
    g.loadData();
  }
}

public void drawGraphs() {
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

public void drawConsole() {
  fill(0);
  rect(0, height - 25, width, 25);
  fill(255);
  textAlign(LEFT);
  text(": " + getConsole(), 5, (height - 25) + 0.8f*25);
}

public void mousePressed() {
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

public void keyPressed() {
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
public void buttonLogic(Button currentButton, String s, boolean isChild) {
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

public void serialStart() {
  setConsole("Broadcasting START command");
  port.write("R");
}
public void serialStop() {
  setConsole("Broadcasting STOP command");
  port.write("S");
}
public void serialCalibrate() {
  setConsole("Broadcasting CALIBRATE command");
  port.write("C");
}
public void serialGain(String text, int value) {
  if (value > 0 && value < 9) {
    setConsole("Broadcasting GAIN. Setting to " + text);
    port.write("G" + value);
  } else {
    setConsole("Error broadcasting GAIN command");
  }
}
public void serialFrequency(String text, int value) {
  if (value > 0 && value < 6) {
    setConsole("Broadcasting FREQUENCY. Setting to " + text);
    port.write("F" + value);
  } else {
    setConsole("Error broadcasting FREQUENCY command");
  }
}
public void serialPrecision(String text, int value) {
  if (value > 0 && value < 3) {
    setConsole("Broadcasting PRECISION. Setting to " + text);
    port.write("P" + value);
  } else {
    setConsole("Error broadcasting PRECISION command");
  }
}
public void serialTransmit() {
  if (currentMote < numberOfMotes) {
    transmission = true;
  } else {
    transmission = false;
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
public void serialEvent(Serial p) {
  timeStamp = millis();
  String str = p.readStringUntil('\n');
  if (str != null) {
    str = trim(str);
  }
  if (hasOutput && str != null && str.charAt(0) != 'M') {
    output.println(str);
  }
}

// File Methods.
public PrintWriter openFile(String filename) {
  hasOutput = true;
  return createWriter(filename);
}
public void closeFile(PrintWriter fileDescriptor) {
  hasOutput = false;
  fileDescriptor.flush();
  fileDescriptor.close();
}
public void setConsole(String s) {
  console = s;
  drawConsole();
}
public String getConsole() {
  return console;
}
class Button {
  public static final int bnWidth = 120;
  public static final int bnHeight = 25;
  protected int xPos;
  protected int yPos;
  protected String text;
  protected boolean active;
  private ArrayList<Button> children;
  
  Button(int x, int y, boolean a, String s) {
    xPos = x;
    yPos = y;
    text = s;
    active = a;
    children = new ArrayList<Button>();
  }
  
  public void showChildren() {
    MenuButton mb;
    for (int i = 0; i < children.size(); i++) {
      mb = (MenuButton) children.get(i);
      mb.setVisible(!mb.isVisible());
    }
  }
  
  public boolean isClicked(int x, int y) {
    if (x >= xPos && x <= (xPos + bnWidth) &&
        y >= yPos && y <= (yPos + bnHeight) &&
        active) {
      showChildren();
      return true;
    } else {
      return false;
    }
  }
  
  public boolean isChildClicked(int x, int y) {
    MenuButton b;
    for (int i = 0; i < children.size(); i++) {
      b = (MenuButton) children.get(i);
      if (x >= b.getX() && x <= (b.getX() + bnWidth) &&
          y >= b.getY() && x <= (b.getY() + bnHeight) &&
          b.isVisible()) {
        showChildren();
        return true;
      }
    }
    return false;
  }
  
  public MenuButton getChildClicked(int x, int y) {
    MenuButton b;
    for (int i = 0; i < children.size(); i++) {
      b = (MenuButton) children.get(i);
      if (x >= b.getX() && x <= (b.getX() + bnWidth) &&
          y >= b.getY() && y <= (b.getY() + bnHeight)) {
        return b;
      }
    }
    return null;
  }
  
  public MenuButton addChild(String t, int v) {
    MenuButton mb = new MenuButton(this, t, v);
    children.add(mb);
    return mb;
  }
  
  // Getters & Setters
  public int getX() {
    return xPos;
  }
  public int getY() {
    return yPos;
  }
  public String getText() {
    return text;
  }
  public void setActive(boolean state) {
    active = state;
  }
  public boolean isActive() {
    return active;
  }
  public ArrayList<Button> getChildren() {
    return children;
  }
}
class Graph {
  public static final int gWidth = 400;
  public static final int gHeight = 200;
  public static final int gScrollWidth = 16;
  public static final int gScrollHeight = 16;
  
  private int xPos;
  private int yPos;
  public HScrollbar scroll;
  public String filename;
  private ArrayList<Integer> dataPoints;
  
  public Graph(int x, int y) {
    xPos = x;
    yPos = y;
    // Position the scrollbar at the bottom of the graph, overlayed.
    scroll = new HScrollbar(xPos, yPos + gHeight - (gScrollHeight / 2), gWidth, gScrollWidth, gScrollHeight);
    dataPoints = new ArrayList<Integer>();
  }
  
  public void loadData() {
    dataPoints = new ArrayList<Integer>();
    String[] lines = loadStrings(filename);
    int max = 0;
    for (int i = 0; i < lines.length; i++) {
      if (Integer.parseInt(lines[i]) > max) {
        max = Integer.parseInt(lines[i]);
      }
    }
    double scale = (double) Graph.gHeight/max;
    for (int i = 0; i < lines.length; i++) {
      dataPoints.add((int) Math.round(scale * Integer.parseInt(lines[i])));
    }
  }
  
  public void showData() {
    fill(0);
    int lowerBound = round(scroll.getPos());
    int upperBound;
    if ((lowerBound + Graph.gWidth) > dataPoints.size()) {
      upperBound = dataPoints.size();
    } else {
      upperBound = lowerBound + Graph.gWidth;
    }
    int j = 0;
    for (int i = round(scroll.getPos()); i < upperBound; i++) {
      rect(j + xPos, yPos + Graph.gHeight, 1, (-1)*dataPoints.get(i));
      j++;
    }
  }
  
  // Getters & Setters.
  public int getX() {
    return xPos;
  }
  public int getY() {
    return yPos;
  }
  public ArrayList<Integer> getData() {
    return dataPoints;
  }
}
class HScrollbar {
  int swidth, sheight;    // width and height of bar
  float xpos, ypos;       // x and y position of bar
  float spos, newspos;    // x position of slider
  float sposMin, sposMax; // max and min values of slider
  int loose;              // how loose/heavy
  boolean over;           // is the mouse over the slider?
  boolean locked;
  float ratio;

  HScrollbar (float xp, float yp, int sw, int sh, int l) {
    swidth = sw;
    sheight = sh;
    int widthtoheight = sw - sh;
    ratio = (float)sw / (float)widthtoheight;
    xpos = xp;
    ypos = yp-sheight/2;
    spos = xpos;// + swidth/2 - sheight/2;
    newspos = spos;
    sposMin = xpos;
    sposMax = xpos + swidth - sheight;
    loose = l;
  }

  public void update() {
    if (overEvent()) {
      over = true;
    } else {
      over = false;
    }
    if (mousePressed && over) {
      locked = true;
    }
    if (!mousePressed) {
      locked = false;
    }
    if (locked) {
      newspos = constrain(mouseX-sheight/2, sposMin, sposMax);
    }
    if (abs(newspos - spos) > 1) {
      spos = spos + (newspos-spos)/loose;
    }
  }

  public float constrain(float val, float minv, float maxv) {
    return min(max(val, minv), maxv);
  }

  public boolean overEvent() {
    if (mouseX > xpos && mouseX < xpos+swidth &&
       mouseY > ypos && mouseY < ypos+sheight) {
      return true;
    } else {
      return false;
    }
  }

  public void display() {
    noStroke();
    fill(204);
    rect(xpos, ypos, swidth, sheight);
    if (over || locked) {
      fill(0, 0, 0);
    } else {
      fill(102, 102, 102);
    }
    rect(spos, ypos, sheight, sheight);
  }

  public float getPos() {
    // Convert spos to be values between
    // 0 and the total width of the scrollbar
    return spos * ratio;
  }
}
class MenuButton extends Button {
  private boolean visible;
  private Button parent;
  private int value;
  
  public MenuButton(Button p, String t, int v) {
    super(p.getX() + Button.bnWidth + 2, p.getY() + Button.bnHeight*p.getChildren().size(), p.isActive(), t);
    parent = p;
    value = v;
  }
  
  // Getters & Setters.
  public boolean isVisible() {
    return visible;
  }
  public void setVisible(boolean v) {
    visible = v;
  }
  public int getValue() {
    return value;
  }
}
class VScrollbar {
  int swidth, sheight;    // width and height of bar
  float xpos, ypos;       // x and y position of bar
  float spos, newspos;    // x position of slider
  float sposMin, sposMax; // max and min values of slider
  int loose;              // how loose/heavy
  boolean over;           // is the mouse over the slider?
  boolean locked;
  float ratio;

  VScrollbar (float xp, float yp, int sw, int sh, int l) {
    swidth = sw;
    sheight = sh;
    int widthtoheight = sw - sh;
    ratio = (float)sw / (float)widthtoheight;
    xpos = xp;
    ypos = yp-sheight/2;
    spos = xpos;// + swidth/2 - sheight/2;
    newspos = spos;
    sposMin = xpos;
    sposMax = xpos + swidth - sheight;
    loose = l;
  }

  public void update() {
    if (overEvent()) {
      over = true;
    } else {
      over = false;
    }
    if (mousePressed && over) {
      locked = true;
    }
    if (!mousePressed) {
      locked = false;
    }
    if (locked) {
      newspos = constrain(mouseX-sheight/2, sposMin, sposMax);
    }
    if (abs(newspos - spos) > 1) {
      spos = spos + (newspos-spos)/loose;
    }
  }

  public float constrain(float val, float minv, float maxv) {
    return min(max(val, minv), maxv);
  }

  public boolean overEvent() {
    if (mouseX > xpos && mouseX < xpos+swidth &&
       mouseY > ypos && mouseY < ypos+sheight) {
      return true;
    } else {
      return false;
    }
  }

  public void display() {
    noStroke();
    fill(204);
    rect(xpos, ypos, sheight, swidth);
    if (over || locked) {
      fill(0, 0, 0);
    } else {
      fill(102, 102, 102);
    }
    rect(ypos, spos, sheight, sheight);
  }

  public float getPos() {
    // Convert spos to be values between
    // 0 and the total width of the scrollbar
    return spos * ratio;
  }
}
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "baseStationGUI2" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
