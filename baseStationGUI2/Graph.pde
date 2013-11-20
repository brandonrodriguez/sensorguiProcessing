class Graph {
  public static final int gWidth = 400;
  public static final int gHeight = 200;
  public static final int gScrollWidth = 16;
  public static final int gScrollHeight = 16;
  
  private int xPos;
  private int yPos;
  private color gC;
  public HScrollbar scroll;
  public String filename;
  private ArrayList<Integer> dataPoints;
  
  public Graph(int x, int y, color c) {
    xPos = x;
    yPos = y;
    gC = c;
    // Position the scrollbar at the bottom of the graph, overlayed.
    scroll = new HScrollbar(xPos, yPos + gHeight - (gScrollHeight / 2), gWidth, gScrollWidth, gScrollHeight);
    dataPoints = new ArrayList<Integer>();
  }
  
  public void loadData() {
    dataPoints = new ArrayList<Integer>();
    String[] lines = loadStrings(filename);
    String[] settings = lines[0].split(" ");
    int precision;
    if (settings[1].equals("L")) {
      precision = 16;
    } else {
      precision = 24;
    }
    int gain = (int) Math.pow(2, Integer.parseInt(settings[2]));
    double vref = Double.parseDouble(settings[3]);
    int max = 0;
    int min = (int) Math.pow(2, 16);
    for (int i = 1; i < lines.length; i++) {
      if (Integer.parseInt(lines[i]) > max) {
        max = Integer.parseInt(lines[i]);
      }
      if (Integer.parseInt(lines[i]) < min) {
        min = Integer.parseInt(lines[i]);
      }
    }
    int range = max - min;
    double scale = (double) Graph.gHeight/range;
    for (int i = 1; i < lines.length; i++) {
      //dataPoints.add((int) Math.round(scale * (Integer.parseInt(lines[i]) - min)));
      // Graphed points have values between -120 and +120 (roughly). This range is larger than the height of the graph, so also scale.
      dataPoints.add((int) ((100*((( Integer.parseInt(lines[i])*1.0 / Math.pow(2, precision - 1)) - 1) * vref) / (1.0*gain))*(200/240.0)));
      println(dataPoints.get(dataPoints.size() -1));
    }

  }
  
  /*public void showData() {
    fill(gC);
    // scroll.getPos() - 6;
    for (int i = 0; i < dataPoints.size(); i++) {
      rect(xPos + i, yPos + Graph.gHeight, 1,  (-1)*dataPoints.get(i));
    }
  }*/
  
  public void showData() {
    fill(gC);
    int lowerBound, upperBound;
    
    // scroll.getPos() has a range of 0 to (Graph.gWidth - 12) = 388. This is not always enough to view all
    // data points, so we need to weight the scroll of 1px of the scroller to dataPoints.size() / 388.
    lowerBound = (int) (1.0 * (round(scroll.getPos()) - xPos - 6) * (dataPoints.size() / (Graph.gWidth - 12)));
    if ((lowerBound + Graph.gWidth) > dataPoints.size()) {
      upperBound = dataPoints.size();
    } else {
      upperBound = lowerBound + Graph.gWidth;
    }
    
    int j = 0;
    for (int i = lowerBound; i < upperBound; i++) {
      rect(j + xPos, yPos + (Graph.gHeight / 2), 1, (-1)*dataPoints.get(i));
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
