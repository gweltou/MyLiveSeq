import java.util.concurrent.Callable;

static final boolean DEBUG = false;

static final int ALIGN_ROW = 1;
static final int ALIGN_COLUMN = 2;
static final int ALIGN_HORIZONTALLY = 4;
static final int ALIGN_VERTICALLY = 8;
static final int ALIGN_RIGHT = 16;
static final int ALIGN_TOP = 32;



/************************************************
 ******************  HELPERS  *******************
 ************************************************/
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
  float x = random(amp);
  float y = random(amp-x);
  float z = random(amp-x-y);
  x -= amp/2; y-=amp/2; z-=amp/2;
  float tmp;
  // Shuffle
  for (int i=0; i<3; i++) {
    switch (floor(random(3))) {
      case 0: tmp=x; x=y; y=tmp;
              break;
      case 1: tmp=x; x=z; z=tmp;
              break;
      case 2: tmp=y; y=z; z=tmp;
              break;
      default: break;
    }
  }
  return color(red(c)+x, green(c)+y, blue(c)+z);
}



static class UI {
  private Window root;

  public UI() { }

  public void setWindow(Window r) { root=r; }
  public Window getWindow() { return root; }
  public void render() { root.render(); }

  public void keyPressed(KeyEvent event) { root.keyPressed(event); }
  public void mousePressed(MouseEvent event) { root.mousePressed(event); }
  public void mouseReleased(MouseEvent event) { root.mouseReleased(event); }
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
  public boolean colorFixed;
  public boolean sizeFixed;
  private float posX = 0;
  private float posY = 0;
  private float scaleX = 1.0f;
  private float scaleY = 1.0f;
  private float width;
  private float height;
  private boolean dirty = false; // If size has changed

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
  public float getHeight() { return this.height; }
  public void setSize(float w, float h) {
    if (!sizeFixed) {
      this.width = w; 
      this.height = h;
    }
  }
  public void setSizeFixed() { sizeFixed=true; }
  public void setSizeFixed(float w, float h) { setSize(w, h); sizeFixed=true; }
  public void updateSize() { }
  public boolean isDirty() { 
    if (sizeFixed)
      return false;
    return dirty;
  }
  public void setDirty(boolean t) { dirty=t; }
  public void refresh() { }
  public void setColor(color c) { 
    if (!colorFixed) {
      col = c;
      dark = dark(c);
      darker = darker(c);
      light = light(c);
      lighter = lighter(c);
    }
  }
  public void setColorFixed() {
    colorFixed=true;
  }
  public void setColorFixed(color c) {
    setColor(c);
    colorFixed=true;
  }

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
    if (DEBUG) {
      stroke(255,0,0);
      strokeWeight(2);
      noFill();
      rect(getAbsoluteX(), getAbsoluteY(), getWidth(), getHeight());
    }
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
  public boolean keyPressed(KeyEvent e) { return false; }
  public boolean mousePressed(MouseEvent e) { return false; }
  public boolean mouseReleased(MouseEvent e) { return false; }
  public boolean mouseClicked(MouseEvent e) { return false; }
  public boolean mouseDragged(MouseEvent e) { return false; }
}



/***************************************************
 ********************** WINDOW *********************
 ***************************************************/
class Window extends Container {
  private Element draggedElement = null;
  private Element selectedElement = null;
  private final UI ui;
  private float scaleX = 1.0f;
  private float scaleY = 1.0f;

  public Window(UI ui) {
    this.ui = ui;
  }
  
  public float getScaleX() { return scaleX; }
  public float getScaleY() { return scaleY; }
  public void setScaleX(float x) { scaleX = x; }
  public void setScaleY(float y) { scaleY = y; }
  public void registerDragged(Element element) { draggedElement = element; }
  public Element getDragged() { return draggedElement; }
  public void unregisterDragged() { draggedElement = null; }
  public void registerSelected(Element element) { selectedElement = element; }
  public Element getSelected() { return selectedElement; }
  public void unregisterSelected() { selectedElement = null; }

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
}



/***************************************************
 ******************  CONTAINER  ********************
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
  public void clear() { children.clear(); }
  public void setWindow(Window w) {
    // Cascade down to give children a reference to root Window
    super.setWindow(w);
    for (Element child : getChildren()) {
      child.setWindow(w);
    }
  }
  public ArrayList<Element> getChildren() { return children; }
  
  public void setColor(color c) {
    super.setColor(c);   // Sets own color
    for (Element child : getChildren()) {
      child.setColor(c);
    }
  }
  
  public void setSpacing(float s) { spacing=s; }
  public void setPadding(float p) { padding=p; }
  public float getPadding() { return padding; }
  public void setAlign(int align) { 
    this.align = align; 
    align();
  }
  public int getAlign() { return this.align; }

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
      y = 0;
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
    if ((align & ALIGN_RIGHT) != 0) {
      float w = getWidth();
      for (Element child : getChildren()) {
        x = child.getX() + w-child.getWidth();
        child.setX(x);
      }
    }
    if ((align & ALIGN_TOP) != 0) {
      for (Element child : getChildren()) {
        child.setY(0);
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
  private float minWidth = 0f;
  private float minHeight = 0f;

  public DynamicContainer() {
    super();
  }

  public void add(Element element) {
    super.add(element);
    align();
    shrink();
  }
  public void add(int idx, Element element) {
    super.add(idx, element);
    align();
    shrink();
  }
  public void remove(Element element) {
    super.remove(element);
    align();
    shrink();
  }

  public float getWidth() {
    if (!sizeFixed)
      updateSize();
    return Math.max(minWidth, super.getWidth());
  }
  public float getHeight() {
    if (!sizeFixed)
      updateSize();
    return Math.max(minHeight, super.getHeight());
  }
  /*
  public float getAbsoluteX() {
    if (dirty)
      updateSize();
    return super.getAbsoluteX() + getPadding();
  }
  public float getAbsoluteY() {
    if (dirty)
      updateSize();
    return super.getAbsoluteY() + getPadding();
  }*/
  
  public void setSize(float x, float y) { 
    super.setSize(x, y); 
    setDirty(false);
  }
  public void setMinSize(float x, float y) { 
    minWidth=x; 
    minHeight=y;
    setDirty(false);
  }

  public void align() {
    if (getAlign() != 0) {
      super.align();
      setDirty(true);
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
    setDirty(true);
  }
  public void refresh() {
    // Force updating size, used when isDirty tag is not possible
    for (Element child : getChildren()) {
      child.refresh();
      child.setDirty(true);
    }
    align();
    //shrink();
    updateSize();
  }
  public void updateSize() {
    // Calculate size of outer area
    // Never executed if sizeFixed flag is set
    
    float maxWidth = minWidth-getPadding();
    float maxHeight = minHeight-getPadding();

    for (Element child : getChildren()) {
      // Recursively ask every child to update their own size
      if (child.isDirty())
        child.updateSize();
      
      if (child.getX()+child.getWidth() > maxWidth)
        maxWidth = child.getX()+child.getWidth();
      if (child.getY()+child.getHeight() > maxHeight)
        maxHeight = child.getY()+child.getHeight();
    }
    setSize(maxWidth+2*getPadding(), maxHeight+2*getPadding());
    setDirty(false);
  }
}



/***************************************************
 ******************* DRAG PANE *********************
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
    //setSize(textWidth(s), textAscent());
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
 *********************  BUTTON  ********************
 ***************************************************/
class Button extends DynamicContainer {
  private Label label = null;
  protected boolean pressed = false;
  private int textSize = 14;

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
  
  public void setTextSize(int size) {
    textSize = size;
    if (label!=null)
      label.setTextSize(size);
    align();
    shrink();
  }

  public void setValue(String value) {
    label = new Label(value);
    label.setTextSize(textSize);
    getChildren().clear();
    add(label);
  }

  public void action() { }

  public void press() { pressed = true; }
  public void release() { pressed = false; }

  public boolean mousePressed(MouseEvent event) {
    if (event.getButton() == LEFT) {
      press();
      return true;
    }
    return false;
  }
  public boolean mouseClicked(MouseEvent event) {
    release();
    action();
    return true;
  }
  public boolean mouseDragged(MouseEvent event) {
    release();
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
  protected boolean toggled = false;

  public ToggleButton() {
    super();
  }
  public ToggleButton(String s) {
    super(s);
  }
  
  public void toggle() {
    toggled =! toggled;
    if (toggled) press();
    else release();
  }
  public void unToggle() {
    toggled = false;
    release();
  }
  public boolean isToggled() { return toggled; }

  public boolean mouseClicked(MouseEvent event) {
    super.mouseClicked(event);
    toggle();
    return true;
  }
  
  public void render() {
    if (isToggled()) {
      pressed = true;
    }
    super.render();
  }
}



/***************************************************
 *******************  TOGGLE LED  ******************
 ***************************************************/
class ToggleLed extends ToggleButton {
  public color radiant;
  
  public ToggleLed() {
    super();
  }
  
  public void setColor(color c) {
    super.setColor(c);
    radiant = colMult(c, 1.8);
  }
  
  public void render() {
    noStroke();
    if (isToggled()) {
      fill(radiant);
      ellipse(getX()-2, getY()-2, getWidth()+4, getHeight()+4);
      fill(col);
      ellipse(getX(), getY(), getWidth(), getHeight());
      fill(radiant);
      ellipse(getX()+2, getY()+2, getWidth()-4, getHeight()-4);
      //ellipse(getX()+2, getY()+2, getWidth()*0.4, getHeight()*0.4);
    } else {
      fill(dark);
      ellipse(getX(), getY(), getWidth(), getHeight());
      //fill(getParent().dark);
      //ellipse(getX()+2, getY()+2, getWidth()-4, getHeight()-4);
    }
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
  private float angle;
  private float minAngle, maxAngle;
  
  public Knob() {
    super();
    setSize(28, 28);
    setColor(lighter);
    setAngleBoundaries(PI-0.8, TWO_PI+0.8);
  }
  
  public void setAngle(float a) { angle=a; }
  public void setAngleBoundaries(float min, float max) {
    minAngle = min;
    maxAngle = max;
  }
  public float getMinAngle() { return minAngle; }
  public float getMaxAngle() { return maxAngle; }
  
  public void render() {
    stroke(dark);
    strokeWeight(5);
    noFill();
    arc(getX(), getY(), getWidth(), getHeight(), getMinAngle(), getMaxAngle());
    fill(lighter);
    stroke(darker);
    strokeWeight(0.5);
    ellipse(getX(), getY(), getWidth(), getHeight());
    
    // Knob value marquer
    float r = 0.33 * getWidth();
    float mx = r*cos(angle);
    float my =  -r*sin(angle);
    strokeWeight(5);
    point(mx + getX()+0.5*getWidth(), my + getY()+0.5*getHeight());
    strokeWeight(3);
    line(mx + getX()+0.5*getWidth(), my + getY()+0.5*getHeight(),
         0.5*mx + getX()+0.5*getWidth(), 0.5*my + getY()+0.5*getHeight());
    
  }
}



/***************************************************
 ******************** CONTROLLER *******************
 ***************************************************/
public class Controller extends DynamicContainer {
  private Label label;
  private Knob knob;
  private Label valueLabel;
  private float rawValue;
  private float minValue = 0;
  private float maxValue = 127;

  public Controller(String s) {
    super();
    label = new Label(s);
    label.setTextSize(12);
    knob = new Knob();
    rawValue = 127;
    setBoundaries(0, 127);
    valueLabel = new Label(String.valueOf(round(rawValue)));
    valueLabel.setTextSize(12);
    
    setPadding(2);
    setSpacing(1);
    setAlign(ALIGN_COLUMN + ALIGN_VERTICALLY);
    add(label);
    add(knob);
    add(valueLabel);
  }
  
  public void setBoundaries(float min, float max) { minValue=min; maxValue=max; }
  
  public void setValue(float val) {
    rawValue = constrain(val, minValue, maxValue);
    valueLabel.setValue(String.valueOf(round(rawValue)));
    float angle = map(round(rawValue), minValue, maxValue, knob.getMinAngle(), knob.getMaxAngle());
    knob.setAngle(-angle);
  }
  
  public boolean mouseDragged(MouseEvent event) {
    if (getWindow().getDragged() == null) {
      getWindow().registerDragged(this);
      return true;
    }
    if (getWindow().getDragged() == this) {
      float scale = 1.0f;
      if (event.isControlDown())
        scale = 0.2f;
      setValue(rawValue + scale*0.005*(maxValue-minValue)*(pmouseY-mouseY));
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
