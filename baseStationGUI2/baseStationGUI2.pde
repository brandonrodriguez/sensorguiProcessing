// BaseStation v2.0
// Toilers 2013
// Original Author: Brandon Rodriguez (brodrigu@mines.edu)

// Imports.
import processing.serial.*;

class BaseStation {
  // Set the length of time to wait (in ms) before querying the next mote for data.
  final int transmissionTimeout = 500;
  
  // A list of buttons to display.
  ArrayList<Button> buttons;
  boolean preReq;
  
  // A list of graphs to draw (note this is populated by the user's input of number of motes).
  ArrayList<Graph> graphs;
  color[] graphColors;
  
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
  int consoleTimeout;
  
  // Used to determine if we are currently attempting to transmit data in the draw function.
  boolean transmission;
  int currentMote;
  
  HashMap<String, Character> settings;
  
  // *** IN PROGRESS ***
  VScrollbar verticalScroll;
  
  public BaseStation(Serial p) {
    // Instantiate global variable objects.
    buttons = new ArrayList<Button>();
    graphs = new ArrayList<Graph>();
    graphColors = new color[5];
    graphColors[0] = #FF0000;
    graphColors[1] = #00FF00;
    graphColors[2] = #0000FF;
    graphColors[3] = #0FF000;
    graphColors[4] = #000FF0;
    font = createFont("Segoe UI", 20, true);
    port = p;
    numberOfMotes = 0;
    setMotes = false;
    settings = new HashMap<String, Character>();
    verticalScroll = new VScrollbar(width - 16, 0, height, 16, 16);
    console = "";
    preReq = false;
  }
  
  void createLayout() {
    for (int i = 0; i < numberOfMotes; i++) {
      graphs.add(new Graph(20 + Button.bnWidth, 60 + i*Graph.gHeight, graphColors[i]));
    }
    buttons.add(new Button(this, 10, 60 + 0*Button.bnHeight, false, "Start"));
    buttons.add(new Button(this, 10, 70 + 1*Button.bnHeight, false, "Stop"));
    buttons.add(new Button(this, 10, 80 + 2*Button.bnHeight, false, "Calibrate"));
    buttons.add(new Button(this, 10, 90 + 3*Button.bnHeight, true, "Gain"));
    Button gain = buttons.get(buttons.size() - 1);
    gain.addChild("1", 1);
    gain.addChild("2", 2);
    gain.addChild("4", 3);
    gain.addChild("8", 4);
    gain.addChild("16", 5);
    gain.addChild("32", 6);
    gain.addChild("64", 7);
    gain.addChild("128", 8);
    buttons.add(new Button(this, 10, 100 + 4*Button.bnHeight, false, "Frequency"));
    Button frequency = buttons.get(buttons.size() - 1);
    frequency.addChild("10 Samples", 1);
    frequency.addChild("100 Samples", 2);
    frequency.addChild("200 Samples", 3);
    frequency.addChild("250 Samples", 4);
    frequency.addChild("500 Samples", 5);
    buttons.add(new Button(this, 10, 110 + 5*Button.bnHeight, true, "Precision"));
    Button precision = buttons.get(buttons.size() - 1);
    precision.addChild("16 bit", 'L');
    precision.addChild("24 bit", 'H');
    buttons.add(new Button(this, 10, 120 + 6*Button.bnHeight, true, "Debug Info"));
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
    if (initPrereq() == true) {
      initButtons();
    } else if (preReq == false) {
      setConsole("Set Precision & Gain before sampling data.");
    }
  }
  
  boolean initPrereq() {
    if (settings.get("Precision") != null && settings.get("Gain") != null) {
      if (preReq == false) {
        preReq = true;
        return true;
      }
    }
    return false;
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
      fill(0);
      rect(g.getX(), g.getY() + (Graph.gHeight / 2), Graph.gWidth, 1);
      text("0", g.getX() + Graph.gWidth - 5, g.getY() + (Graph.gHeight / 2));
      text("1.2V", g.getX() + Graph.gWidth - 20, g.getY() + 15);
      text("-1.2V", g.getX() + Graph.gWidth - 20, g.getY() + Graph.gHeight - 20);
      g.scroll.update();
      g.scroll.display();
    }
  }
  
  void drawConsole() {
    fill(0);
    rect(0, height - 25, width, 25);
    fill(255);
    textAlign(LEFT);
    if ((millis() - consoleTimeout) > 5000) {
      text(":", 5, (height - 25) + 0.8*25);
    } else {
      text(": " + getConsole(), 5, (height - 25) + 0.8*25);
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
        char state = cb.getState();
        serialPrecision(text, state);
      }
    } else if (s.equals("Debug Info")) {
      for (int i = 0; i < numberOfMotes; i++) {
        println(graphs.get(i).filename);
        println(graphs.get(i).getData().size());
        println(settings.get("Precision"));
        println(settings.get("Gain"));
        println(settings.get("Frequency"));
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
  void serialPrecision(String text, char state) {
      setConsole("Broadcasting PRECISION. Setting to P" + state);
      port.write("P" + state);
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
  
  // File Methods.
  PrintWriter openFile(String filename) {
    hasOutput = true;
    PrintWriter temp = createWriter(filename);
    temp.println("BASE " + settings.get("Precision") + " " + settings.get("Gain") + " 1.225");
    return temp;
  }
  void closeFile(PrintWriter fileDescriptor) {
    hasOutput = false;
    fileDescriptor.flush();
    fileDescriptor.close();
  }
  void setConsole(String s) {
    console = s;
    consoleTimeout = millis();
    drawConsole();
  }
  String getConsole() {
    return console;
  }
}

BaseStation bs;
Serial p = new Serial(this, Serial.list()[0], 57600);
void setup() {
  size(600,675);
  bs = new BaseStation(p);

}

void draw() {
  textFont(bs.font, 16);
  background(128);
  if (!bs.setMotes) {
    fill(255);
    rect(0, 0, width, 50);
    fill(0);
    textAlign(CENTER);
    text("Please type the number of motes to communicate with,", width / 2, 25*0.8);
    text("then hit enter to begin.", width / 2, 50*0.8);
  } else {
    if (bs.transmission && (millis() - bs.timeStamp) > bs.transmissionTimeout) {
      bs.closeFile(bs.output);
      bs.serialTransmit();
    }
    bs.drawTitle();
    bs.drawGraphs();
    bs.drawConsole();
    bs.drawButtons();
    bs.verticalScroll.update();
    bs.verticalScroll.display();
  }
}

void serialEvent(Serial p) {
  bs.timeStamp = millis();
  String str = p.readStringUntil('\n');
  if (str != null) {
    str = trim(str);
  }
  if (bs.hasOutput && str != null && str.charAt(0) != 'M') {
    bs.output.println(str);
  }
  if (str != null && str.charAt(0) == 'M') {
    bs.setConsole(str);
  }
}

void mousePressed() {
  Button b;
  for (int i = 0; i < bs.buttons.size(); i++) {
    b = bs.buttons.get(i);
    if (b.isClicked(mouseX, mouseY)) {
      bs.buttonLogic(b, b.getText(), false);
      return;
    }
    if (b.isChildClicked(mouseX, mouseY)) {
      MenuButton child = b.getChildClicked(mouseX, mouseY);
      bs.buttonLogic(child, b.getText(), true);
      return;
    }
  }
}

void keyPressed() {
  if (!bs.setMotes) {
    if (key == 10 || key == 13) {
      if (bs.numberOfMotes > 0) {
        bs.setMotes = true;
        bs.createLayout();
        return;
      }
    }
    if (key >= '0' && key <= '9') {
      bs.numberOfMotes = (bs.numberOfMotes * 10) + Character.getNumericValue(key);
    }
  }
}
