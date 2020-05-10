/***************************************************
 ********************* TOOL BAR ********************
 ***************************************************/
class ToolBar extends DynamicContainer {
  public ToolBar() {
    super();
    setAlign(ALIGN_ROW);
    //setColor(color(180));
    setSpacing(4);
    setPadding(3);
    
    DynamicContainer btnBox = new DynamicContainer();
    btnBox.setSpacing(3);
    btnBox.setPadding(2);
    add(btnBox);
    Button playBtn = new Button("PLAY");
    btnBox.add(playBtn);
    Button stopBtn = new Button("STOP");
    btnBox.add(stopBtn);
    btnBox.setAlign(ALIGN_COLUMN + ALIGN_VERTICALLY);
    
    Controller tempoCtrl = new Controller("BPM");
    tempoCtrl.setBoundaries(20, 400);
    tempoCtrl.setValue(120);
    add(tempoCtrl);
  }
  
  public void setColor(color c) {
    super.setColor(colMult(c, 1.4));
  }
  
  public void render() {
    noStroke();
    fill(col);
    rect(getX(), getY(), getWidth(), getHeight());
    super.render();
    stroke(dark);
    strokeWeight(1.6);
    line(getX(), getHeight(), getWidth(), getHeight());
  }
}



/***************************************************
 ******************* BOTTOM BAR ********************
 ***************************************************/
class BottomBar extends Container {
  public DynamicContainer center = new DynamicContainer();

  public BottomBar() {
    super();
    setPadding(3);
    setAlign(ALIGN_VERTICALLY);
    center.setSpacing(3);
    center.setAlign(ALIGN_ROW);
    add(center);
  }
  
  public void setColor(color c) {
    super.setColor(colMult(c, 1.4));
  }
  
  public void render() {
    fill(col);
    noStroke();
    rect(getX(), getY(), getWidth(), getHeight());
    
    stroke(dark);
    float weight = 1.6;
    strokeWeight(weight);
    line(getX(), getY(), getX()+width, getY());
    super.render();
  }
}




/***************************************************
 ***************** TRACKS WINDOW *******************
 ***************************************************/
class TracksWindow extends Window {
  private final TracksToolBar toolBar;
  private final TracksDragPane centerPane;
  private final DynamicContainer tracksContainer;

  public TracksWindow(UI ui) {
    super(ui);
    setWindow(this);
        
    centerPane = new TracksDragPane();
    centerPane.setSize(width, height);
    add(centerPane);
    
    tracksContainer = new DynamicContainer();
    centerPane.add(tracksContainer);
    for (int nt=0; nt<3; nt++) {
      TrackContainer track = new TrackContainer();
      tracksContainer.add(track);
      for (int i=0; i<5; i++) {
        PatternUI pat = new PatternUI();
        pat.setSize(random(40, 100), 64);
        track.addPattern(pat);
        pat.fixColor();
      }
    }
    Button btnAdd = new ButtonAdd();
    tracksContainer.add(btnAdd);
    
    tracksContainer.setPos(10, 100);
    tracksContainer.setSpacing(4);
    tracksContainer.setAlign(ALIGN_COLUMN);
    
    toolBar = new TracksToolBar();
    add(toolBar);
    
    TracksBottomBar bottomBar = new TracksBottomBar();
    add(bottomBar);
  }
  
  public void render() {
    super.render();
    // Draw dragged Element on top of everything
    if (getDragged() != null && getDragged().getClass()==PatternUI.class) {
      getDragged().render();
    }
  }
  
  
  /***************************************************
   ******************* ADD BUTTON ********************
   ***************************************************/
  private class ButtonAdd extends Button {
    public ButtonAdd() {
      super("Add");
    }
    public void action() {
      TrackContainer track = new TrackContainer();
      tracksContainer.add(tracksContainer.getChildren().size()-1, track);
      PatternUI pat = new PatternUI();
      track.addPattern(pat);
      pat.setSize(random(40, 100), 64);
      pat.fixColor();
      getWindow().registerSelected(pat);
    }
  }
  
  
  /***************************************************
   ***************** TRACKS TOOL BAR *****************
   ***************************************************/
  class TracksToolBar extends ToolBar {
    public TracksToolBar() {
      super();
      
      Controller channelCtrl = new Controller("CHAN");
      channelCtrl.setBoundaries(1, 16);
      channelCtrl.setValue(1);
      DynamicContainer spacer = new DynamicContainer();
      spacer.setMinSize(5, 0);
      add(spacer);
      
      add(channelCtrl);
      Controller octaveCtrl = new Controller("OCT");
      octaveCtrl.setBoundaries(-4, 4);
      octaveCtrl.setValue(0);
      add(octaveCtrl);
      Controller transposeCtrl = new Controller("TRA");
      transposeCtrl.setBoundaries(-12, 12);
      transposeCtrl.setValue(0);
      add(transposeCtrl);
      Controller swingCtrl = new Controller("SWIN");
      add(swingCtrl);
      Controller speedCtrl = new Controller("SPEED");
      add(speedCtrl);
      Controller randomCtrl = new Controller("RAND");
      add(randomCtrl);
      
      setSize(width, getHeight());
    }
  }
  
  
  /***************************************************
   *************** TRACKS BOTTOM BAR *****************
   ***************************************************/
  class TracksBottomBar extends BottomBar {
    public TracksBottomBar() {
      super();
      Button midiBtn = new Button("Midi Conf.");
      center.add(midiBtn);
      Button peBtn = new ButtonEdit();
      center.add(peBtn);
      Button loadBtn = new Button("Load");
      center.add(loadBtn);
      Button saveBtn = new Button("Save");
      center.add(saveBtn);
      
      setSize(width, center.getHeight()+2*getPadding());
      setPos(0, height-getHeight());
      align();
    }
    
    private class ButtonEdit extends Button {
      public ButtonEdit() {
        super("Edit");
      }
      public void action() {
        patternWindow.show();
      }
    }
  }
    

  /***************************************************
   ***************  TRACK CONTAINER  *****************
   ***************************************************/
  class TrackContainer extends DynamicContainer {
    private DynamicContainer msButtons;
    private PatternContainer patterns;

    public TrackContainer() {
      super();
      setAlign(ALIGN_ROW);
      
      // Left toggle buttons (mute, solo, loop)
      msButtons = new DynamicContainer();
      add(msButtons);
      msButtons.setPadding(3);
      msButtons.setSpacing(2);
      msButtons.setAlign(ALIGN_COLUMN);
      float toggleSize = 18;
      ToggleButton muteToggle = new ToggleButton();
      muteToggle.setSize(toggleSize, toggleSize);
      msButtons.add(muteToggle);
      muteToggle.setColor(color(244, 0, 0));
      ToggleButton soloToggle = new ToggleButton();
      soloToggle.setSize(toggleSize, toggleSize);
      msButtons.add(soloToggle);
      soloToggle.setColor(color(150, 150, 244));
      TriStateButton loopToggle = new TriStateButton();
      loopToggle.setSize(toggleSize, toggleSize);
      msButtons.add(loopToggle);
      loopToggle.setColor(color(240, 240, 0));
      
      // Patterns
      patterns = new PatternContainer();
      add(patterns);
    }

    public void addPattern(PatternUI pattern) {
      patterns.add(pattern);
    }
    public void addPattern(int idx, PatternUI pattern) {
      //pattern.setY(0);
      patterns.add(idx, pattern);
    }

    public void setColor(color c) {
      super.setColor(colNoise(c, 50));
    }
  }
  
  
  /***************************************************
   **************** PATTERNS CONTAINER ***************
   ***************************************************/
  class PatternContainer extends DynamicContainer {
    private boolean dropable = false;
    private float spacerIndex;
    private float spacerWidth = 32;
    
    public PatternContainer() {
      super();
      setMinSize(16, 64);
      setAlign(ALIGN_ROW);
    }
    
    public void add(Element pattern) {
      pattern.setY(0);
      super.add(pattern);
    }
    public void add(int idx, Element pattern) {
      pattern.setY(0);
      super.add(idx, pattern);
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
      // Select patterns container when flying on top with a pattern
      if (getDragged() != null && getDragged().getClass() == PatternUI.class) {
        registerSelected(this);
      }
      return super.mouseDragged(event);
    }
    public boolean mouseReleased(MouseEvent event) {
      // Check if a dragged Pattern is above
      Element dragged = getDragged();
      if (dragged != null && dragged.getClass() == PatternUI.class) {
        // Capture Pattern
        // Find array index correponding to mouse pointer position
        float pointerLocalX = event.getX()-getAbsoluteX();
        float rightBoundary = 0f;
        ArrayList<Element> patterns = getChildren();
        for (int i=0; i<=patterns.size(); i++) {
          if (i==patterns.size() || pointerLocalX < rightBoundary+patterns.get(i).getWidth()/2) {
            ((Container) dragged.getParent()).remove(dragged);
            // Insert element in position
            this.add(i, dragged);
            unregisterDragged();
            registerSelected(dragged);
            break;
          }
          rightBoundary += getChildren().get(i).getWidth();
        }
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
    public TracksDragPane() {
      super();
    }
    
    public boolean mouseClicked(MouseEvent event) {
      boolean accepted = super.mouseClicked(event);
      if (accepted == false) {
        unregisterSelected();
      }
      return accepted;
    }
  }

  /***************************************************
   *******************   PATTERN   *******************
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
    
    public void setColor(color c) {
      super.setColor(colMult(colNoise(colSat(c, 1.2), 14), 1.33));
    }
    
    /*public boolean mouseReleased(MouseEvent event) {
      if (getDragged() == this) {
        registerSelected(this);
        return false;
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
        if (getParent().getClass() == PatternContainer.class) {
          // Detach from parent TrackContainer
          ((PatternContainer) getParent()).remove(this);
          // Add pattern to centerPane
          centerPane.add(this);
        } else if (getParent().getClass() == TracksDragPane.class) {
          // Center on mouse cursor
          setX(mouseX-getWidth()/2);
          setY(mouseY-getHeight()/2);
        }
      }
      return false;
    }

    public void render() {
      stroke(dark);
      strokeWeight(1);
      fill(col);
      if (getSelected()==this || getSelected()==getParent()) {
        // Selected
        fill(light);
      } else if (getDragged()==this) {
        fill(lighter);
      }
      rect(getX(), getY(), getWidth(), getHeight());
    }
  }
}
