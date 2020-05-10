import java.util.concurrent.Callable;


static final int ALIGN_ROW = 1;
static final int ALIGN_COLUMN = 2;
static final int ALIGN_HORIZONTALLY = 4;
static final int ALIGN_VERTICALLY = 8;


public color lighter(color c) { return colMult(c, 1.3); }
public color light(color c) { return colMult(c, 1.15); }
public color dark(color c) { return colMult(c, 0.75); }
public color darker(color c) { return colMult(c, 0.5); }
public color colMult(color c, float mul) {
  // not sure if clamping is needed...
  color col = color(min(255, red(c)*mul),
                    min(255, green(c)*mul),
                    min(255, blue(c)*mul));
  return col;
}
public color colSat(color c, float amp) {
  float r = red(c);
  float v = green(c);
  float b = blue(c);
  float bri = (r+v+b) / 3;
  return color(round(bri + (r-bri)*amp),
               round(bri + (v-bri)*amp),
               round(bri + (b-bri)*amp));
}
public color colNoise(color c, float amp) {
  return color(red(c)+random(-amp, amp),
               green(c)+random(-amp, amp),
               blue(c)+random(-amp, amp));
}



static class UI {
  private Window root;

  public UI() {
  }

  public void setWindow(Window r) { 
    root=r;
  }
  public Window getWindow() { return root; }
  public void render() { root.render(); }

  public void mousePressed(MouseEvent event) { 
    root.mousePressed(event);
  }
  public void mouseReleased(MouseEvent event) { 
    root.mouseReleased(event);
  }
  public void mouseClicked(MouseEvent event) { 
    root.mouseClicked(event);
  }
  public void mouseDragged(MouseEvent event) { 
    root.mouseDragged(event);
  }
}



/***************************************************
 ***********  Abstract Element Class  **************
 ***************************************************/
class Element {
  private Element parent = null;
  private Window window;
  public color col = color(127);
  public color dark, darker, light, lighter;
  private boolean colorFixed;
  private float posX = 0;
  private float posY = 0;
  private float scaleX = 1.0f;
  private float scaleY = 1.0f;
  private float width;
  private float height;

  public Element() {
  }

  public float getX() { return posX; }
  public float getY() { return posY; }
  public void setX(float x) { posX=x; }
  public void setY(float y) { posY=y; }
  public void setPos(float x, float y) { 
    posX=x; 
    posY=y;
  }
  public float getWidth() { return this.width; }
  public float getHeight() { 
    return this.height;
  }
  public void setSize(float w, float h) { 
    this.width = w; 
    this.height = h;
  } 
  public void setColor(color c) { 
    if (!colorFixed) {
      col = c;
      dark = dark(c);
      darker = darker(c);
      light = light(c);
      lighter = lighter(c);
    }
  }
  public void fixColor() { colorFixed=true; }

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

  public void setParent(Element element) {
    parent = element;
    if (element != null) {
      setWindow(parent.getWindow());
      setColor(parent.col);
    }
  }
  public Element getParent() { return parent; }
  public void setWindow(Window w) { window=w;}
  public Window getWindow() { return window; }
  
  public void render() {
    fill(col);
    noStroke();
    rect(getX(), getY(), getWidth(), getHeight());
  }
  public boolean mousePressed(MouseEvent e) { 
    return false;
  }
  public boolean mouseReleased(MouseEvent e) { 
    return false;
  }
  public boolean mouseClicked(MouseEvent e) { 
    return false;
  }
  public boolean mouseDragged(MouseEvent e) { 
    return false;
  }
}



/***************************************************
 ********************** WINDOW *********************
 ***************************************************/
class Window extends Container {
  private Element draggedElement = null;
  private Element selectedElement = null;
  private final UI ui;

  public Window(UI ui) {
    this.ui = ui;
  }

  public void registerDragged(Element element) { 
    draggedElement = element;
  }
  public Element getDragged() { 
    return draggedElement;
  }
  public void unregisterDragged() { 
    draggedElement = null;
  }

  public void registerSelected(Element element) { 
    selectedElement = element;
  }
  public Element getSelected() { 
    return selectedElement;
  }
  public void unregisterSelected() { 
    selectedElement = null;
  }

  public void show() { 
    ui.setWindow(this);
  }

  public boolean mouseReleased(MouseEvent event) {
    boolean accepted = super.mouseReleased(event);
    draggedElement = null;
    return accepted;
  }
  public boolean mouseDragged(MouseEvent event) {
    boolean accepted = false;
    if (draggedElement != null) {
      // Send event to dragged element directly (useful for knobs)
      accepted = draggedElement.mouseDragged(event);
    }
    return accepted ? accepted : super.mouseDragged(event);
  }

  public void render() {
    super.render();
    if (getSelected() != null) {
      // Draw selection hint around selected object
      float x = getSelected().getAbsoluteX();
      float y = getSelected().getAbsoluteY();
      float w = getSelected().getWidth();
      float h = getSelected().getHeight();
      noFill();
      stroke(getSelected().lighter, 200);
      strokeWeight(4);
      rect(x, y, w, h);
    }
    // Draw dragged Element on top of everything
    if (draggedElement != null) {
      draggedElement.render();
    }
  }
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
  public void setWindow(Window w) {
    // Cascade down to give children a reference to root Window
    super.setWindow(w);
    for (Element child : getChildren()) {
      child.setWindow(w);
    }
  }
  public ArrayList<Element> getChildren() {
    return children;
  }
  
  public void setColor(color c) {
    super.setColor(c);   // Sets own color
    for (Element child : getChildren()) {
      child.setColor(c);
    }
  }
  
  public void setSpacing(float s) { 
    spacing=s;
  }
  public void setPadding(float p) { 
    padding=p;
  }
  public float getPadding() { 
    return padding;
  }
  public void setAlign(int align) { 
    this.align = align; 
    align();
  }
  public int getAlign() { 
    return this.align;
  }

  public void align() {
    float x, y;
    if ((align & ALIGN_ROW) != 0) {
      x = getPadding();
      for (Element child : getChildren()) {
        child.setX(x);
        x += child.getWidth() + spacing;
      }
    }
    if ((align & ALIGN_COLUMN) != 0) {
      y = getPadding();
      for (Element child : getChildren()) {
        child.setY(y);
        y += child.getHeight() + spacing;
      }
    }
    if ((align & ALIGN_HORIZONTALLY) != 0) {
      for (Element child : getChildren()) {
        y = getHeight()/2 - child.getHeight()/2;
        child.setY(y);
      }
    }
    if ((align & ALIGN_VERTICALLY) != 0) {
      for (Element child : getChildren()) {
        x = getWidth()/2 - child.getWidth()/2;
        child.setX(x);
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
    pushMatrix();
    translate(getX()+getPadding(), getY()+getPadding());
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
    shrink();
    dirty = true;
  }
  public void add(int idx, Element element) {
    super.add(idx, element);
    align();
    shrink();
    dirty = true;
  }
  public void remove(Element element) {
    super.remove(element);
    align();
    shrink();
    dirty = true;
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

  public void setSize(float x, float y) { 
    super.setSize(x, y); 
    dirty=false;
  }
  public void setMinSize(float x, float y) { 
    minWidth=x; 
    minHeight=y;
    dirty=true;
  }

  public void align() {
    if (getAlign() != 0) {
      super.align();
      dirty = true;
    }
  }
  
  public void shrink() {
    // Reposition every child so there's no empty room around
    float xoff = 9999;
    float yoff = 9999;
    for (Element child : getChildren()) {
      xoff = min(child.getX(), xoff);
      yoff = min(child.getY(), yoff);
    }
    for (Element child : getChildren()) {
      child.setPos(child.getX()-xoff, child.getY()-yoff);
    }
  }
  
  protected void updateSize() {
    // Calculate size of outer area
    float maxWidth = minWidth-getPadding();
    float maxHeight = minHeight-getPadding();

    for (Element child : getChildren()) {
      if (child.getX()+child.getWidth() > maxWidth)
        maxWidth = child.getX()+child.getWidth();
      if (child.getY()+child.getHeight() > maxHeight)
        maxHeight = child.getY()+child.getHeight();
    }
    setSize(maxWidth+2*getPadding(), maxHeight+2*getPadding());
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
  private int textWeight = 16;

  public Label(String s) {
    super();
    value = s;
    setTextSize(16);
  }

  public void setValue(String s) {
    value = s;
    setSize(textWidth(s), textAscent());
  }
  public void setColor(color c) {
    super.setColor(darker(c));
  }

  public void setTextSize(int weight) {
    textWeight=weight;
    textSize(textWeight);
    setSize(textWidth(value), textAscent());
  }

  public void render() {
    textSize(textWeight);
    fill(dark);
    pushMatrix();
    translate(0, getHeight()-textDescent()/2);
    text(value, getX(), getY());
    popMatrix();
  }
}



/***************************************************
 ****************** Button Element *****************
 ***************************************************/
class Button extends DynamicContainer {
  private Label label = null;
  private boolean pressed = false;

  public Button() {
    super();
    setPadding(4);
    setAlign(ALIGN_HORIZONTALLY + ALIGN_VERTICALLY);
  }

  public Button(String value) {
    this();
    setValue(value);
  }
  
  public void setColor(color c) {
    super.setColor(light(c));
  }

  public void setValue(String value) {
    label = new Label(value);
    label.setTextSize(14);
    getChildren().clear();
    add(label);
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
    // Draw background
    noStroke();
    fill(pressed ? dark : col);
    rect(getX(), getY(), getWidth(), getHeight(), 6);
    
    // Draw Children
    super.render();
    
    // Draw border
    noFill();
    stroke(pressed ? dark : darker);
    strokeWeight(0.5);
    rect(getX(), getY(), getWidth(), getHeight(), 6);
  }
}



/***************************************************
 ******************* TOGGLE BUTTON *****************
 ***************************************************/
class ToggleButton extends Button {
  private boolean toggled = false;

  public ToggleButton() {
    super();
  }

  public boolean mouseClicked(MouseEvent event) {
    super.mouseClicked(event);
    toggled = !toggled;
    return true;
  }

  public void render() {
    noStroke();
    if (toggled) {
      drawToggled();
    } else {
      drawUntoggled();
    }
  }

  private void drawToggled() {
    fill(lighter);
    ellipse(getX()-2, getY()-2, getWidth()+4, getHeight()+4);
    fill(col);
    ellipse(getX(), getY(), getWidth(), getHeight());
    fill(lighter);
    ellipse(getX()+2, getY()+2, getWidth()-4, getHeight()-4);
    //ellipse(getX()+2, getY()+2, getWidth()*0.4, getHeight()*0.4);
  }
  private void drawUntoggled() {
    fill(darker);
    ellipse(getX(), getY(), getWidth(), getHeight());
    fill(dark);
    ellipse(getX()+2, getY()+2, getWidth()-4, getHeight()-4);
  }
}



/***************************************************
 ****************** TRISTATE BUTTON ****************
 ***************************************************/
class TriStateButton extends ToggleButton {
  //private color col1, col2, col3;
  private int state = 0;

  public TriStateButton() {
    super();
  }

  public void setState(int s) { 
    state = s;
  }

  public boolean mouseClicked(MouseEvent event) {
    super.mouseClicked(event);
    state = (state+1)%3;
    return true;
  }

  public void render() {
    noStroke();
    switch (state) {
    case 0: 
      fill(darker, 120);
      ellipse(getX(), getY(), getWidth(), getHeight());
      break;
    case 1: 
      fill(col, 100);
      ellipse(getX(), getY(), getWidth(), getHeight());
      break;
    case 2: 
      fill(lighter, 40);
      ellipse(getX()-2, getY()-2, getWidth()+4, getHeight()+4);
      fill(lighter);
      ellipse(getX(), getY(), getWidth(), getHeight());
      fill(255, 64);
      ellipse(getX()+2, getY()+2, getWidth()-4, getHeight()-4);
      break;
    default: 
      break;
    }
  }
}



/***************************************************
 ********************** KNOB ***********************
 ***************************************************/
public class Knob extends Element {
  public Knob() {
    super();
    setSize(28, 28);
    setColor(lighter);
  }
  
  public void render() {
    stroke(dark, 180);
    strokeWeight(5);
    noFill();
    arc(getX(), getY(), getWidth(), getHeight(), PI-0.8, TWO_PI+0.8);
    fill(lighter);
    stroke(darker);
    strokeWeight(0.5);
    ellipse(getX(), getY(), getWidth(), getHeight());
    
    // Knob value marquer
    float angle = HALF_PI;
    float r = 0.33 * getWidth();
    float mx = getX() + 0.5*getWidth() + r*cos(angle);
    float my = getY() + 0.5*getHeight() - r*sin(angle);
    strokeWeight(5);
    point(mx, my);
  }
}



/***************************************************
 ******************** CONTROLLER *******************
 ***************************************************/
public class Controller extends DynamicContainer {
  private Label label;
  private Knob knob;
  private Label valueLabel;
  private float value;

  public Controller(String s) {
    super();
    label = new Label(s);
    label.setTextSize(12);
    knob = new Knob();
    valueLabel = new Label("120");
    valueLabel.setTextSize(12);
    
    setPadding(2);
    setSpacing(1);
    setAlign(ALIGN_COLUMN + ALIGN_VERTICALLY);
    add(label);
    add(knob);
    add(valueLabel);
  }
  
  public boolean mouseDragged(MouseEvent event) {
    if (getWindow().getDragged() == null) {
      getWindow().registerDragged(this);
      return true;
    }
    if (getWindow().getDragged() == this) {
      value += pmouseY-mouseY;
      valueLabel.setValue(String.valueOf(value));
      return true;
    }
    return false;
  }
  
  public void render() {
    fill(light);
    noStroke();
    rect(getX(), getY(), getWidth(), getHeight(), 6);
    super.render();
  }
}
