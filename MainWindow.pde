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
    ui.setRoot(this);
  }

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
  private final TracksDragPane centerPane;
  private final DynamicContainer tracksContainer;

  public TracksWindow(UI ui) {
    super(ui);

    centerPane = new TracksDragPane();
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
        track.addPattern(pat);
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
    
    private DynamicContainer msButtons;
    private PatternContainer patterns;

    public TrackContainer() {
      super();
      setAlign(ALIGN_ROW);
      
      // Left toggle buttons (mute, solo, loop)
      msButtons = new DynamicContainer();
      msButtons.setPadding(2);
      msButtons.setSpacing(2);
      msButtons.setAlign(ALIGN_COLUMN);
      float toggleSize = 18;
      ToggleButton muteToggle = new ToggleButton();
      muteToggle.setSize(toggleSize, toggleSize);
      muteToggle.setColor(color(244, 0, 0));
      ToggleButton soloToggle = new ToggleButton();
      soloToggle.setSize(toggleSize, toggleSize);
      soloToggle.setColor(color(120, 180, 255));
      TriStateButton loopToggle = new TriStateButton();
      loopToggle.setSize(toggleSize, toggleSize);
      loopToggle.setColor(color(255, 255, 0));
      msButtons.add(muteToggle);
      msButtons.add(soloToggle);
      msButtons.add(loopToggle);
      
      // Patterns
      patterns = new PatternContainer();
            
      add(msButtons);
      add(patterns);
    }

    public void addPattern(PatternUI pattern) {
      pattern.setY(0);
      patterns.add(pattern);
    }
    public void addPattern(int idx, PatternUI pattern) {
      pattern.setY(0);
      patterns.add(idx, pattern);
    }

    /*
    public boolean mouseClicked(MouseEvent event) {
     registerSelected(this);
     return super.mouseClicked(event);
     }*/
  }
  
  
  /***************************************************
   **************** PATTERNS CONTAINER ***************
   ***************************************************/
  class PatternContainer extends DynamicContainer {
    private boolean dropable = false;
    private float spacerIndex;
    private float spacerWidth = 32;
    
    public PatternContainer() {
      setMinSize(16, 64);
      setAlign(ALIGN_ROW);
    }
    
    public void remove(PatternUI pattern) {
      super.remove(pattern);
      // Delete whole track if empty
      if (getChildren().size() == 0) {
        if (getSelected() == this)
          unregisterSelected();
        tracksContainer.remove(this.getParent());
      }
    }
    
    public float getWidth() {
      if (dropable) {
        return spacerWidth + super.getWidth();
      } else {
        return super.getWidth();
      }
    }
    
    public boolean mouseDragged(MouseEvent event) {
      if (getDragged() != null) {
        registerSelected(this);
      }
      //registerSelected(this);
      return super.mouseDragged(event);
    }
    public boolean mouseReleased(MouseEvent event) {
      // Check if a dragged Pattern is above
      PatternUI dragged = (PatternUI) getDragged();
      if (dragged != null && dragged.getClass() == PatternUI.class) {
        // Pattern captured
        // Find array index correponding to mouse pointer position
        float pointerLocalX = event.getX()-getAbsoluteX();
        float rightBoundary = 0f;
        ArrayList<Element> patterns = getChildren();
        for (int i=0; i<=patterns.size(); i++) {
          if (i==patterns.size() || pointerLocalX < rightBoundary+patterns.get(i).getWidth()/2) {
            // Insert element in position
            ((Container) dragged.getParent()).remove(dragged);
            patterns.add(i, dragged);
            unregisterDragged();
            break;
          }
          rightBoundary += getChildren().get(i).getWidth();
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
   ***************** TRACKS DRAG PANE ****************
   ***************************************************/
  class TracksDragPane extends DragPane {
    public boolean mouseClicked(MouseEvent event) {
      boolean accepted = super.mouseClicked(event);
      if (accepted == false) {
        unregisterSelected();
      }
      return accepted;
    }
  }

  /***************************************************
   **************** PatternUI Element ****************
   ***************************************************/
  class PatternUI extends Element {
    private float scaleX = 1.0f;
    private float scaleY = 1.0f;

    public PatternUI() {
      super();
    }

    public void setScaleX(float sc) { 
      scaleX=sc;
    }
    public void setScaleY(float sc) { 
      scaleY=sc;
    }
    //public float getX() { return super.getX()*scaleX; }
    //public float getY() { return super.getY()*scaleY; }
    public float getWidth() { 
      return super.getWidth()*scaleX;
    }
    public float getHeight() { 
      return super.getHeight()*scaleY;
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
        if (getParent().getClass() == PatternContainer.class) {
          setX(event.getX()-getWidth()/2);
          setY(event.getY()-getHeight()/2);
          ((PatternContainer) getParent()).remove(this);
          centerPane.add(this);
        }
        float dx = mouseX - pmouseX;
        float dy = mouseY - pmouseY;
        setX(getX()+dx);
        setY(getY()+dy);
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
