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
