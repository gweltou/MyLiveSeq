import java.util.concurrent.Callable;

static final int ALIGN_ROW = 1;
static final int ALIGN_COLUMN = 2;
static final int ALIGN_CENTER = 3;



class UI {
  private Element root;
  
  public UI() {}
  
  public void setRoot(Element r) { root=r; }
  public void render() { root.render(); }
  
  public void mousePressed(MouseEvent event) { root.mousePressed(event); }
  public void mouseReleased(MouseEvent event) { root.mouseReleased(event); }
  public void mouseClicked(MouseEvent event) { root.mouseClicked(event); }
  public void mouseDragged(MouseEvent event) { root.mouseDragged(event); }
}



/***************************************************
 ***********  Abstract Element Class  **************
 ***************************************************/
class Element {
  private Element parent = null;
  private color col = color(255, 0);
  private float posX = 0;
  private float posY = 0;
  private float scaleX = 1.0f;
  private float scaleY = 1.0f;
  private float width;
  private float height;
  
  public Element() {}
  
  public float getX() { return posX; }
  public float getY() { return posY; }
  public void setX(float x) { posX=x; }
  public void setY(float y) { posY=y; }
  public void setPos(float x, float y) { posX=x; posY=y; }
  public float getWidth() { return this.width; }
  public float getHeight() { return this.height; }
  public void setSize(float w, float h) { this.width = w; this.height = h; }
  public void setColor(color c) { col = c; }
  public color getColor() { return col; }
  
  public float getAbsoluteX() {
    if (parent == null)
      return getX();
    return parent.getAbsoluteX() + getX();
  }
  public float getAbsoluteY() {
    if (parent == null)
      return getY();
    return parent.getAbsoluteY() + getY();
  }
  
  public boolean containsAbsolutePoint(float x, float y) {
    return x > getAbsoluteX() && x < (getAbsoluteX()+getWidth()) &&
           y > getAbsoluteY() && y < (getAbsoluteY()+getHeight());
  }
  
  public void setParent(Element element) { parent = element; }
  public Element getParent() { return parent; }
  
  public void render() {
    fill(col);
    noStroke();
    rect(getX(), getY(), getWidth(), getHeight());
  }
  public boolean mousePressed(MouseEvent e) { return false; }
  public boolean mouseReleased(MouseEvent e) { return false; }
  public boolean mouseClicked(MouseEvent e) { return false; }
  public boolean mouseDragged(MouseEvent e) { return false; }
}



/***************************************************
 *************** Container Element *****************
 ***************************************************/
class Container extends Element {
  private ArrayList<Element> children = new ArrayList();
  private float spacing = 0f;
  private float padding = 0f;
  private int align = 0;
  
  public Container() {
    super();
  }
  
  public void add(Element element) {
    children.add(element);
    element.setParent(this);
  }
  public void add(int idx, Element element) {
    children.add(idx, element);
    element.setParent(this);
  }
  public void remove(Element element) {
    children.remove(element);
    element.setParent(null);
  }
  
  public ArrayList<Element> getChildren() {
    return children;
  }
    
  public void setSpacing(float s) { spacing=s; }
  public void setPadding(float p) { padding=p; }
  public float getPadding() { return padding; }
  public void setAlign(int align) { this.align = align; align(); }
  public int getAlign() { return this.align; }
  
  public void align() {
    float x = getPadding();
    float y = getPadding();
    if (align == ALIGN_ROW) {
      for (Element child : getChildren()) {
        child.setX(x);
        child.setY(y);
        x += child.getWidth() + spacing;
      }
    } else if (align == ALIGN_COLUMN) {
      for (Element child : getChildren()) {
        child.setX(x);
        child.setY(y);
        y += child.getHeight() + spacing;
      }
    } else if (align == ALIGN_CENTER) {
      for (Element child : getChildren()) {
        x += getWidth()/2 - child.getWidth()/2;
        y += getHeight()/2 - child.getHeight()/2;
        child.setX(x);
        child.setY(y);
      }
    }
  }
  
  public boolean mousePressed(MouseEvent event) {
    boolean accepted = false;
    for (int i=getChildren().size()-1; i>=0; i--) {
      if (getChildren().get(i).containsAbsolutePoint(event.getX(), event.getY())) {
        accepted = getChildren().get(i).mousePressed(event);
        if (accepted) break;
      }
    }
    return accepted;
  }
  public boolean mouseReleased(MouseEvent event) {
    boolean accepted = false;
    for (int i=getChildren().size()-1; i>=0; i--) {
      if (getChildren().get(i).containsAbsolutePoint(event.getX(), event.getY())) {
        accepted = getChildren().get(i).mouseReleased(event);
        if (accepted) break;
      }
    }
    return accepted;
  }
  public boolean mouseClicked(MouseEvent event) {
    boolean accepted = false;
    for (int i=getChildren().size()-1; i>=0; i--) {
      if (getChildren().get(i).containsAbsolutePoint(event.getX(), event.getY())) {
        accepted = getChildren().get(i).mouseClicked(event);
        if (accepted) break;
      }
    }
    return accepted;
  }
  public boolean mouseDragged(MouseEvent event) {
    boolean accepted = false;
    for (int i=getChildren().size()-1; i>=0; i--) {
      if (getChildren().get(i).containsAbsolutePoint(event.getX(), event.getY())) {
        accepted = getChildren().get(i).mouseDragged(event);
        if (accepted) break;
      }
    }
    return accepted;
  }
  
  public void render() {
    super.render();
    pushMatrix();
    translate(getX(), getY());
    for (Element child : children) {
      child.render();
    }
    popMatrix();
  }
}



/***************************************************
 **************** Dynamic Container ****************
 ***************************************************/
class DynamicContainer extends Container {
  // This container updates its size automatically
  private boolean dirty = false;
  private float minWidth = 0f;
  private float minHeight = 0f;
  
  public DynamicContainer() {
    super();
  }
  
  public void add(Element element) {
    super.add(element);
    align();
  }
  public void add(int idx, Element element) {
    super.add(idx, element);
    align();
  }
  public void remove(Element element) {
    super.remove(element);
    align();
  }
  
  public float getWidth() {
    if (dirty)
      updateSize();
    return Math.max(minWidth, super.getWidth());
  }
  public float getHeight() {
    if (dirty)
      updateSize();
    return Math.max(minHeight, super.getHeight());
  }
  
  public void setSize(float x, float y) { super.setSize(x, y); dirty=false; }
  public void setMinSize(float x, float y) { minWidth=x; minHeight=y; }
  
  public void align() {
    if (getAlign() != 0) {
      super.align();
      dirty = true;
    }
  }
  
  protected void updateSize() {
    float maxWidth = minWidth;
    float maxHeight = minHeight;
    
    for (Element child : getChildren()) {
      if (child.getX()+child.getWidth() > maxWidth)
        maxWidth = child.getX()+child.getWidth();
      if (child.getY()+child.getHeight() > maxHeight)
        maxHeight = child.getY()+child.getHeight();
    }
    setSize(maxWidth+getPadding(), maxHeight+getPadding());
    dirty = false;
  }
}



/***************************************************
 ******************* Drag Pane *********************
 ***************************************************/
class DragPane extends Container {
  public DragPane() {
    super();
  }
  
  public boolean mouseDragged(MouseEvent event) {
    // Move world if right mouse drag
    if (event.getButton() == RIGHT) {
      for (Element child : getChildren()) {
        float dx = mouseX - pmouseX;
        float dy = mouseY - pmouseY;
        child.setX(child.getX() + dx);
        child.setY(child.getY() + dy);
      }
      return false;
    }
    return super.mouseDragged(event);
  }
  
  public void render() {
    pushMatrix();
    translate(getX(), getY());
    super.render();
    popMatrix();
  }
}



/***************************************************
 *********************** Label *********************
 ***************************************************/
class Label extends Element {
  private String value;
  
  public Label(String s) {
    value = s;
    setSize(textWidth(s), textAscent()+textDescent());
    setColor(color(0, 255));
  }
  
  public void setValue(String s) {
    value = s;
    setSize(textWidth(s), textAscent()+textDescent());
  }
  
  public void render() {
    fill(getColor());
    pushMatrix();
    translate(0, getHeight()-((Container) getParent()).getPadding());
    text(value, getX(), getY());
    popMatrix();
  }
}



/***************************************************
 ****************** Button Element *****************
 ***************************************************/
class Button extends DynamicContainer {
  //private Label label = null;
  private boolean pressed = false;
  
  public Button() {
    super();
    setPadding(4);
    setAlign(ALIGN_CENTER);
  }
  
  public Button(String value) {
    this();
    add(new Label(value));
  }
  
  public void setValue(String value) {
    getChildren().clear();
    add(new Label(value));
  }
  
  public void action() {
  }
  
  public boolean mousePressed(MouseEvent event) {
    if (event.getButton() == LEFT) {
      pressed = true;
      return true;
    }
    return false;
  }
  public boolean mouseClicked(MouseEvent event) {
    pressed = false;
    action();
    return true;
  }
  public boolean mouseDragged(MouseEvent event) {
    pressed = false;
    return true;
  }
  
  public void render() { 
    stroke(0);
    noStroke();
    if (pressed) {
      fill(140);
    } else {
      fill(220);
    }
    rect(getX(), getY(), getWidth(), getHeight(), 6);
    super.render();
  }
}


class ToggleButton extends Button {
  private boolean toggled = false;
  
  public ToggleButton() {
    super();
  }
  
  public boolean mouseClicked(MouseEvent event) {
    super.mouseClicked(event);
    println("toggle");
    toggled = !toggled;
    return true;
  }
  
  public void render() {
    if (toggled) {
      drawToggled();
    } else {
      drawUntoggled();
    }
  }
  
  private void drawToggled() {
    fill(getColor(), 64);
    ellipse(getX(), getY(), getWidth(), getHeight());
  }
  private void drawUntoggled() {
    fill(getColor(), 255);
    ellipse(getX(), getY(), getWidth(), getHeight());
  }
}


class TriStateButton extends Button {
  private color col1, col2, col3;
  private int state = 0;
  
  public TriStateButton() {
    super();
  }
  
  public void setColor(color col) {
    super.setColor(col);
    col1 = color(red(col)*0.6, green(col)*0.6, blue(col)*0.6);
    col2 = color(red(col)*0.88, green(col)*0.88, blue(col)*0.88);
    col3 = col;
  }
  
  public void setState(int s) { state = s; }
  
  public boolean mouseClicked(MouseEvent event) {
    super.mouseClicked(event);
    println("toggle");
    state = (state+1)%3;
    return true;
  }
  
  public void render() {
    switch (state) {
      case 0: fill(col1, 80);
              break;
      case 1: fill(col2, 180);
              break;
      case 2: fill(col3, 64);
              ellipse(getX()-2, getY()-2, getWidth()+4, getHeight()+4);
              fill(col3);
              break;
    }
    ellipse(getX(), getY(), getWidth(), getHeight());
  }
}
