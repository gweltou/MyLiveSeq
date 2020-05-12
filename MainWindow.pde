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
    
    DynamicContainer transport = new DynamicContainer();
    transport.setSpacing(3);
    transport.setPadding(2);
    add(transport);
    Button playBtn = new PlayButton("PLAY");
    transport.add(playBtn);
    Button stopBtn = new StopButton("STOP");
    transport.add(stopBtn);
    transport.setAlign(ALIGN_COLUMN + ALIGN_VERTICALLY);
    
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
  
  class PlayButton extends Button {
    public PlayButton(String s) {
      super(s);
    }
    public void action() {
      midiManager.play();
    }
  }
  class StopButton extends Button {
    public StopButton(String s) {
      super(s);
    }
    public void action() {
      midiManager.playStop();
    }
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
    setColor(color(127));
        
    centerPane = new TracksDragPane();
    centerPane.setSize(width, height);
    add(centerPane);
    
    tracksContainer = new DynamicContainer();
    centerPane.add(tracksContainer);
    clearTracks();
    for (int nt=0; nt<3; nt++) {
      addTrack(new TrackContainer());
    }
    
    tracksContainer.setPos(10, 100);
    tracksContainer.setSpacing(2);
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
  
  public void addTrack(TrackContainer track) {
    tracksContainer.add(tracksContainer.getChildren().size()-1, track);
  }
  public void clearTracks() {
    tracksContainer.clear();
    tracksContainer.add(new ButtonAdd());
  }
  
  public boolean keyPressed(KeyEvent event) {
    // Zoom In/Out
    if (event.getKey() == 'a') {
      setScaleX(getScaleX()/2);
      tracksContainer.refresh();
    } else if (event.getKey() == 'z') {
      setScaleX(getScaleX()*2);
      tracksContainer.refresh();
    }
    return false;
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
      PatternUI pat = new PatternUI(new Pattern());
      track.addPattern(pat);
      pat.setColorFixed();
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
      Controller randomMelCtrl = new Controller("RND Ml");
      randomMelCtrl.setValue(0);
      add(randomMelCtrl);
      Controller randomRytCtrl = new Controller("RND Ry");
      randomRytCtrl.setValue(0);
      add(randomRytCtrl);
      
      setSizeFixed(width, getHeight());
    }
  }
  
  
  /***************************************************
   *************** TRACKS BOTTOM BAR *****************
   ***************************************************/
  class TracksBottomBar extends BottomBar {
    public TracksBottomBar() {
      super();
      Button midiBtn = new ConfigButton("Midi Conf.");
      center.add(midiBtn);
      Button peBtn = new EditButton("Edit");
      center.add(peBtn);
      Button loadBtn = new LoadButton("Load");
      center.add(loadBtn);
      Button saveBtn = new Button("Save");
      center.add(saveBtn);
      
      setSize(width, center.getHeight()+2*getPadding());
      setPos(0, height-getHeight());
      align();
    }
    
    private class ConfigButton extends Button {
      public ConfigButton(String s) {
        super(s);
        setTextSize(16);
      }
      public void action() {
        new ConfigWindow(ui).show();
      }
    }
    private class EditButton extends Button {
      public EditButton(String s) {
        super(s);
        setTextSize(16);
      }
      public void action() {
        new PatternWindow(ui).show();
      }
    }
    private class LoadButton extends Button {
      public LoadButton(String s) {
        super(s);
        setTextSize(16);
      }
      
      public void action() {
        File inputFile = new File("/home/gweltaz/Dropbox/Projets/Informatique/MyLiveSeq/test2.mid");
        ArrayList<MyTrack> tracks = midiManager.loadMidiFile(inputFile);
        clearTracks();
        for (MyTrack track : tracks) {
          if (track.getPatterns().isEmpty())
            break;
          TrackContainer tc = new TrackContainer();
          for (Pattern pattern : track.getPatterns()) {
            tc.addPattern(new PatternUI(pattern));
          }
          addTrack(tc);
        }
      }
    }
  }
    

  /***************************************************
   ***************  TRACK CONTAINER  *****************
   ***************************************************/
  class TrackContainer extends DynamicContainer {
    // Container for a single Track
    private DynamicContainer msButtons;
    private PatternContainer patterns;
    private DynamicContainer addButtons;

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
      ToggleLed muteToggle = new ToggleLed();
      muteToggle.setSizeFixed(toggleSize, toggleSize);
      msButtons.add(muteToggle);
      muteToggle.setColorFixed(color(244, 0, 0));
      ToggleLed soloToggle = new ToggleLed();
      soloToggle.setSizeFixed(toggleSize, toggleSize);
      msButtons.add(soloToggle);
      soloToggle.setColorFixed(color(140, 120, 244));
      TriStateButton loopToggle = new TriStateButton();
      loopToggle.setSizeFixed(toggleSize, toggleSize);
      msButtons.add(loopToggle);
      loopToggle.setColorFixed(color(240, 240, 0));
      
      // Patterns
      patterns = new PatternContainer();
      add(patterns);
      
      // Add New Pattern Buttons
      addButtons = new DynamicContainer();
      add(addButtons);
      addButtons.add(new AddPatButton("+"));
      
      //addButtons.setAlign(ALIGN_VERTICALLY);
    }
    
    private class AddPatButton extends Button {
      public AddPatButton(String s) {
        super(s);
        setTextSize(16);
      }
      public void action() {
        println("action");
        PatternUI newPattern = new PatternUI(new Pattern());
        addPattern(newPattern);
        newPattern.setColorFixed();
      }
    }
    
    public void addPattern(PatternUI pattern) {
      println("pattern added");
      patterns.add(pattern);
    }
    public void addPattern(int idx, PatternUI pattern) {
      println("pattern added");
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
      ((DynamicContainer) getParent()).align();
      ((DynamicContainer) getParent()).shrink();
    }
    public void add(int idx, Element pattern) {
      pattern.setY(0);
      super.add(idx, pattern);
      ((DynamicContainer) getParent()).align();
      ((DynamicContainer) getParent()).shrink();
    }
    public void remove(PatternUI pattern) {
      super.remove(pattern);
      
      // Delete whole track if empty
      if (getChildren().size() == 0) {
        if (getSelected() == this)
          unregisterSelected();
        tracksContainer.remove(this.getParent());
      }
      
      ((DynamicContainer) getParent()).align();
      ((DynamicContainer) getParent()).shrink();
    }
    
    public float getWidth() {
      return super.getWidth() + spacerWidth;
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
            dropable = false;
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
   ******************   PATTERN_UI   *****************
   ***************************************************/
  class PatternUI extends Element {
    // PatternUI should not be confused with Pattern class
    private final Pattern pattern;

    public PatternUI(Pattern p) {
      super();
      pattern = p;
      setSize(p.getLength()/24, 64);
    }
    
    public void setColor(color c) {
      super.setColor(colMult(colNoise(colSat(c, 1.2), 14), 1.33));
    }
    
    public float getWidth() { return super.getWidth() * getScaleX(); }
    public float getHeight() { return super.getHeight() * getScaleY(); }
    
    public boolean mouseClicked(MouseEvent event) {
      registerSelected(this);
      
      // Cut pattern in two if CTRL key is down
      if(event.isControlDown()) {
        float pointerLocalX = event.getX()-getAbsoluteX();
        // coordinate unit is 24ticks
        int tickCoord = round(pointerLocalX*24/getScaleX());
        int patternIdx = ((Container) getParent()).getChildren().indexOf(this);
        println("cut " +tickCoord + " " +patternIdx);
        Pattern[] divided = pattern.divide(tickCoord);
        println(divided[0].getNotes());
        if (divided[1] != null) {
          Container parent = ((Container) getParent());
          parent.remove(this);
          parent.add(patternIdx, new PatternUI(divided[0]));
          parent.add(patternIdx+1, new PatternUI(divided[1]));
        }
      }
      return true;
    }
    public boolean mouseDragged(MouseEvent event) {
      // Drag only if no other element is being dragged
      if (getDragged() == null) {
        registerDragged(this);
        return true;
      }

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
      
      // Draw notes
      println(getX() + "  " + getY());
      for (MidiNote note : pattern.getNotes()) {
        int pitch = note.getPitch();
        float startX = getX() + note.getStart()*getScaleX()/24;
        float endX = getX() + note.getEnd()*getScaleX()/24;
        line(startX, getY()+64-0.5*pitch, endX, getY()+64-0.5*pitch);
      }
    }
  }
}
