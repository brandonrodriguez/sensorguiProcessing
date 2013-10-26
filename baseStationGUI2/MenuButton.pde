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
