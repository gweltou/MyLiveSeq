class Window extends Container {
  private Element draggedElement = null;
  private Element selectedElement = null;
  private final UI ui;
  
  public Window(UI ui) {
    this.ui = ui;
  }
  
  public void registerDragged(Element element) { draggedElement = element; }
  public Element getDragged() { return draggedElement; }
  public void unregisterDragged() { draggedElement = null; }
  
public void registerSelected(Element element) { selectedElement = element; }
  public Element getSelected() { return selectedElement; }
  public void unregisterSelected() { selectedElement = null; }
  
  public void show() { ui.setRoot(this); }
  
  public boolean mouseReleased(MouseEvent event) {
    boolean accepted = super.mouseReleased(event);
    draggedElement = null;
    return accepted; 
  }/*
  public boolean mouseDragged(MouseEvent event) {
    return super.mouseDragged(event);
  }*/
  
  public void render() {
    super.render();
    if (getSelected() != null) {
      float x = getSelected().getAbsoluteX();
      float y = getSelected().getAbsoluteY();
      float w = getSelected().getWidth();
      float h = getSelected().getHeight();
      noFill();
      stroke(200, 255, 0, 120);
      strokeWeight(10);
      rect(x, y, w, h);
      strokeWeight(7);
      rect(x, y, w, h);
      strokeWeight(5);
      rect(x, y, w, h);
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
 ***************** TRACKS WINDOW *******************
 ***************************************************/
class TracksWindow extends Window {
  private final ToolBar toolBar;
  private final DragPane centerPane;
  private final DynamicContainer tracksContainer;
  
  public TracksWindow(UI ui) {
    super(ui);
    
    centerPane = new DragPane();
    centerPane.setSize(width, height);
    add(centerPane);
    
    toolBar = new ToolBar();
    add(toolBar);
    
    BottomBar bottomBar = new BottomBar();
    add(bottomBar);
        
    tracksContainer = new DynamicContainer();
    centerPane.add(tracksContainer);
    for (int nt=0; nt<3; nt++) {
      TrackContainer track = new TrackContainer();
      for (int i=0; i<5; i++) {
        PatternUI pat = new PatternUI();
        pat.setSize(random(40, 100), 64);
        pat.setColor(color(random(256), random(256), random(256)));
        track.add(pat);
      }
      tracksContainer.add(track);
    }
    Button btnAdd = new ButtonAdd();
    tracksContainer.add(btnAdd);
    
    tracksContainer.setPos(10, 100);
    tracksContainer.setSpacing(4);
    tracksContainer.setAlign(ALIGN_COLUMN);
  }
  
  
  /***************************************************
   ******************* ADD BUTTON ********************
   ***************************************************/
  class ButtonAdd extends Button {
    public ButtonAdd() {
      super("Add");
    }
    public void action() {
      PatternUI pat = new PatternUI();
      pat.setSize(random(40, 100), 64);
      pat.setColor(color(random(256), random(256), random(256)));
      TrackContainer tc = new TrackContainer();
      tc.add(pat);
      tracksContainer.add(tracksContainer.getChildren().size()-1, tc);
      println(tracksContainer.getChildren().size());
    }
  }
  
  
  /***************************************************
   ********************* TOOL BAR ********************
   ***************************************************/
  class ToolBar extends DynamicContainer {
    
    public ToolBar() {
      setPos(0, 10);
      setAlign(ALIGN_ROW);
      setColor(color(180));
      setSpacing(3);
      setPadding(3);
      
      Element spacer = new Element();
      spacer.setColor(0);
      spacer.setSize(1, 24+2*3);
      
      Button playBtn = new Button("PLAY");
      add(playBtn);
      Button stopBtn = new Button("STOP");
      add(stopBtn);
      add(spacer);
      add(new Button("Tp"));
      
      setSize(width, getHeight());
    }
  }
  
  
  /***************************************************
   ******************* BOTTOM BAR ********************
   ***************************************************/
  class BottomBar extends DynamicContainer {
    DynamicContainer center = new DynamicContainer();
    
    public BottomBar() {
      setColor(color(180));
      setPadding(3);
      //setSize(width, 0);
      
      center.setSpacing(3);
      center.setAlign(ALIGN_ROW);
      Button midiBtn = new Button("Midi Conf.");
      center.add(midiBtn);
      Button peBtn = new Button("Edit");
      center.add(peBtn);
      Button loadBtn = new Button("Load");
      center.add(loadBtn);
      Button saveBtn = new Button("Save");
      center.add(saveBtn);
      add(center);
      
      setMinSize(width, 0);
      
      
      
      setAlign(ALIGN_CENTER);
      setSize(width, getHeight());
      println(getHeight());
      setPos(0, height-getHeight()/2-20);
    }
  }
  
  /***************************************************
   ************* TrackContainer Element **************
   ***************************************************/
  class TrackContainer extends DynamicContainer {
    private boolean dropable = false;
    private float spacerIndex;
    private float spacerWidth = 32;
    
    public TrackContainer() {
      super();
      setMinSize(16, 64);
      setAlign(ALIGN_ROW);
    }
    
    public void add(PatternUI pattern) {
      pattern.setY(0);
      super.add(pattern);
    }
    public void add(int idx, PatternUI pattern) {
      pattern.setY(0);
      super.add(idx, pattern);
    }
    public void remove(PatternUI pattern) {
      super.remove(pattern);
      if (getChildren().size() == 0) {
        if (getSelected() == this)
          unregisterSelected();
        tracksContainer.remove(this);
      }
    }
    
    public float getWidth() {
      if (dropable) {
        return spacerWidth + super.getWidth();
      } else {
        return super.getWidth();
      }
    }
    
    /*
    public boolean mouseClicked(MouseEvent event) {
      registerSelected(this);
      return super.mouseClicked(event);
    }*/
    public boolean mouseDragged(MouseEvent event) {
      if (getDragged() != null && getDragged().getClass() == PatternUI.class) {
        println("flying");
        registerSelected(this);
        return true;
      }
      return super.mouseDragged(event);
    }
    public boolean mouseReleased(MouseEvent event) {
      // Check if a dragged Pattern is above
      PatternUI dragged = (PatternUI) getDragged();
      if (dragged != null && dragged.getClass() == PatternUI.class) {
        // Find array index correponding to mouse pointer position
        float pointerLocalX = event.getX()-getAbsoluteX();
        float rightBoundary = 0f;
        ArrayList<Element> patterns = getChildren();
        for (int i=0; i<=patterns.size(); i++) {
          if (i==patterns.size() || pointerLocalX < rightBoundary+patterns.get(i).getWidth()/2) {
            // Insert element in position
            ((Container) dragged.getParent()).remove(dragged);
            add(i, dragged);
            unregisterDragged();
            break;
          }
          rightBoundary += patterns.get(i).getWidth();
        }
        registerSelected(this);
        return true;
      }
      return false;
    }
    
    public void render() {
      dropable = false;
      
      // Check if a dragged Pattern is above
      if (getDragged() != null && getDragged().getClass() == PatternUI.class) {
        if (containsAbsolutePoint(mouseX, mouseY)) {
          dropable = true;
          
          // Find array index correponding to mouse pointer position
          float pointerLocalX = mouseX-getAbsoluteX();
          spacerIndex = 0;
          float rightBoundary = 0f;
          for (Element child : getChildren()) {
            rightBoundary += child.getWidth();
            if (pointerLocalX > rightBoundary-child.getWidth()/2) {
              spacerIndex += 1;
            } else {
              break;
            }
          }
        }
      }
      
      stroke(0);
      pushMatrix();
      translate(getX(), getY());
      int i = 0;
      for (Element child : getChildren()) {
        if (spacerIndex == i++ && dropable) {
          translate(spacerWidth, 0);
        }
        child.render();
      }
      popMatrix();
    }
  }
  
  
  /***************************************************
   **************** PatternUI Element ****************
   ***************************************************/
  class PatternUI extends Element {
    //private color col = color(64, 64, 220);
      
    public PatternUI() {
      super();
    }
    /*
    public boolean mouseReleased(MouseEvent event) {
      if (getDragged() == this) {
        emptyDragged();
        return true;
      }
      return false;
    }*/
    public boolean mouseClicked(MouseEvent event) {
      registerSelected(this);
      return true;
    }
    public boolean mouseDragged(MouseEvent event) {
      // Drag only if no other element is being dragged
      if (getDragged() == null)
        registerDragged(this);
      
      if (getDragged() == this) {        
        // Detach from parent TrackContainer
        if (getParent().getClass() == TrackContainer.class) {
          setX(event.getX()-getWidth()/2);
          setY(event.getY()-getHeight()/2);
          ((TrackContainer) getParent()).remove(this);
          centerPane.add(this);
        }
        float dx = mouseX - pmouseX;
        float dy = mouseY - pmouseY;
        setX(getX()+dx);
        setY(getY()+dy);
        
        return true;
      }
      return false;
    }
    
    public void render() {
      stroke(0);
      strokeWeight(1);
      fill(getColor());
      rect(getX(), getY(), getWidth(), getHeight());
    }
  }
  
}
