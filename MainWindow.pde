public void loadFile(File inputFile) {
  tracksWindow.loadFile(inputFile);
}


int renderCount;
/***************************************************
 ***************** TRACKS WINDOW *******************
 ***************************************************/
class TracksWindow extends Window {
  private final TracksToolBar toolBar;
  private final TracksDragPane centerPane;
  private final DynamicContainer tracksContainer;
  private File fileToLoad = null;
  private MyTrack selectedTrack = null;

  public TracksWindow(UI ui) {
    super(ui);
    setWindow(this);
    setColor(color(127));
        
    centerPane = new TracksDragPane();
    add(centerPane);
    
    tracksContainer = new DynamicContainer();
    centerPane.add(tracksContainer);
    clearTracks();
    for (int nt=0; nt<3; nt++) {
      MyTrack newTrack = new MyTrack();
      midiManager.addTrack(newTrack);
      addTrack(new TrackContainer(newTrack));
    }
    
    tracksContainer.setPos(10, 16);
    tracksContainer.setSpacing(2);
    tracksContainer.setAlign(ALIGN_COLUMN);
    
    toolBar = new TracksToolBar();
    add(toolBar);
    
    TracksBottomBar bottomBar = new TracksBottomBar();
    add(bottomBar);
    
    centerPane.setY(toolBar.getHeight()+1.6);
    centerPane.setSizeFixed(width, height-toolBar.getHeight()-bottomBar.getHeight()-2);
  }
  
  public void loadFile(File inputFile) {
    fileToLoad = inputFile;
  }
  
  public void registerSelected(Element element) {
    super.registerSelected(element);
    centerPane.setRenderDirty();
  }
  
  public void render() {
    // Load a new midi file from fileSelector
    if (fileToLoad != null) {
      ArrayList<MyTrack> tracks = midiManager.loadMidiFile(fileToLoad);
      clearTracks();
      for (MyTrack track : tracks) {
        if (track.getPatterns().isEmpty())
          break;
        TrackContainer tc = new TrackContainer(track);
        addTrack(tc);
      }
      surface.setTitle("MyLiveSeq - "+fileToLoad);
      fileToLoad = null;
    }
    
    renderCount = 0;
    if (centerPane.isRenderDirty()) {
      super.render();
    } else {
      super.renderDirty();
    }
    // Draw dragged Element on top of everything
    //if (getDragged() != null && getDragged().getClass()==PatternUI.class) {
    //  getDragged().render();
    //}
    if (DEBUG && renderCount > 0)
      println("renderCount: " + renderCount);
  }
  
  public void addTrack(TrackContainer trackContainer) {
    tracksContainer.add(tracksContainer.getChildren().size()-1, trackContainer);
  }
  public void clearTracks() {
    tracksContainer.clear();
    tracksContainer.add(new ButtonAddTrack());
  }
  //public ArrayList<TrackContainer> getTracks() {
  //  return tracksContainer.getChildren();
  //}
  public MyTrack getSelectedTrack() { return selectedTrack; }
  public void selectTrack(MyTrack t) {
    // Link the toolbar controllers to the currently selected track
    selectedTrack = t;
    toolBar.setTrack(t);
    println("track selected : "+t);
    //setRenderDirty();
  }
  
  public boolean keyPressed(KeyEvent event) {
    // Zoom In/Out
    if (event.getKey() == 'a') {
      centerPane.translate(-width/2, 0);
      setScaleX(getScaleX()/2);
      /*for (Element child : tracksContainer.getChildren()) {
        if (child.getClass() == TrackContainer.class) {
          for (PatternUI pui : ((TrackContainer) child).getPattern()) {
            pui.scaleX(1.5);
          }
        }
      }*/
      
      centerPane.translate(width/2, 0);
      tracksContainer.refresh();
      centerPane.setRenderDirty();
    } else if (event.getKey() == 'z') {
      centerPane.translate(-width/2, 0);
      setScaleX(getScaleX()*2);
      /*for (Element child : tracksContainer.getChildren()) {
        if (child.getClass() == TrackContainer.class) {
          for (PatternUI pui : ((TrackContainer) child).getPattern()) {
            pui.scaleX(0.5);
          }
        }
      }*/
      
      centerPane.translate(width/2, 0);
      tracksContainer.refresh();
      centerPane.setRenderDirty();
    } else if (event.getKey() == DELETE) {
      if (getSelected()!=null && getSelected().getClass()==PatternUI.class && getDragged()==null) {
        PatternUI pattern = (PatternUI) getSelected();
        unregisterSelected();
        pattern.getTrackUI().removePattern(pattern);
        println("del");
        centerPane.setRenderDirty();
      }
    }
    return false;
  }
  public boolean mouseDragged(MouseEvent event) {
    boolean accepted = false;
    if (getResized() != null) {
      // Send event to dragged element directly (useful for knobs and resizing patterns)
      accepted = getResized().mouseDragged(event);
    }
    return accepted ? accepted : super.mouseDragged(event);
  }
  public boolean mouseReleased(MouseEvent event) {
    // Send signal to pattern that is being resized
    if (getResized() != null) {
      getResized().mouseReleased(event);
      unregisterResized();
      println("unregister resized");
      return true;
    }
    boolean accepted = super.mouseReleased(event);
    return accepted;
  }
  
  
  /***************************************************
   **************** ADD TRACK BUTTON *****************
   ***************************************************/
  private class ButtonAddTrack extends Button {
    public ButtonAddTrack() {
      super("Add");
    }
    public void action() {
      MyTrack track = new MyTrack();
      track.addPattern(new Pattern());
      midiManager.addTrack(track);
      TrackContainer tc = new TrackContainer(track);
      // Add before "Add" button
      tracksContainer.add(tracksContainer.getChildren().size()-1, tc);
      
      getWindow().registerSelected(tc.getChildren().get(0));
    }
  }
  
  
  /***************************************************
   ***************** TRACKS TOOL BAR *****************
   ***************************************************/
  class TracksToolBar extends ToolBar {
    private MyTrack track = null; // Selected track
    private ChannelController channelCtrl;
    private OctaveController octaveCtrl;
    
    public TracksToolBar() {
      super();
      
      DynamicContainer spacer = new DynamicContainer();
      spacer.setMinSize(5, 0);
      add(spacer);
      
      channelCtrl = new ChannelController("CHAN");
      channelCtrl.setBoundaries(1, 16);
      channelCtrl.setValue(1);
      channelCtrl.deactivate();
      add(channelCtrl);
      
      octaveCtrl = new OctaveController("OCT");
      octaveCtrl.setBoundaries(-4, 4);
      octaveCtrl.setValue(0);
      octaveCtrl.deactivate();
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
    
    public void setTrack(MyTrack t) {
      track = t;
      if (t != null) {
        channelCtrl.setValue(track.getChannel()+1);
        channelCtrl.activate();
        octaveCtrl.setValue(track.getOctave());
        octaveCtrl.activate();
      } else {
        channelCtrl.deactivate();
        octaveCtrl.deactivate();
      }
    }
    
    private class ChannelController extends Controller {
      public ChannelController(String s) {
        super(s);
      }
      public void action() {
        println(round(getValue()));
        track.setChannel(round(getValue())-1);
      }
    }
    private class OctaveController extends Controller {
      public OctaveController(String s) {
        super(s);
      }
      public void action() {
        println(round(getValue()));
        track.setOctave(round(getValue()));
      }
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
        if (getSelected() != null && getSelected().getClass() == PatternUI.class) {
          PatternWindow patternWindow = new PatternWindow(ui);
          patternWindow.setPattern( ((PatternUI) getSelected()).getPattern() );
          patternWindow.show();
        }
      }
      void render() {
        if (getSelected( ) != null && getSelected().getClass() == PatternUI.class) {
          activate();
        } else {
          deactivate();
        }
        super.render();
      }
    }
    private class LoadButton extends Button {
      public LoadButton(String s) {
        super(s);
        setTextSize(16);
      }
      
      public void action() {
        selectInput("Load a MIDI file", "loadFile");
      }
    }
  }
    

  /***************************************************
   ***************  TRACK CONTAINER  *****************
   ***************************************************/
  public class TrackContainer extends DynamicContainer {
    // Container for a single Track
    private MyTrack track;
    private DynamicContainer msButtons;
    private PatternContainer patterns;
    private DynamicContainer addButtons;

    public TrackContainer(MyTrack track) {
      super();
      this.track = track;
      setAlign(ALIGN_ROW);
      
      // Left toggle buttons (mute, solo, loop)
      msButtons = new DynamicContainer();
      add(msButtons);
      msButtons.setPadding(3);
      msButtons.setSpacing(2);
      msButtons.setAlign(ALIGN_COLUMN);
      float toggleSize = 16;
      
      msButtons.add(new MuteToggle());
      msButtons.add(new SoloToggle());
      TriStateButton loopToggle = new TriStateButton();
      loopToggle.setSizeFixed(toggleSize, toggleSize);
      msButtons.add(loopToggle);
      loopToggle.setColorFixed(color(240, 240, 0));
      
      // Patterns
      patterns = new PatternContainer();
      add(patterns);
      // Add existing patterns in track
      for (Pattern p : track.getPatterns()) {
        PatternUI pui = new PatternUI(p);
        patterns.add(pui);
        pui.setColorFixed(colMult(colNoise(colSat(pui.col, 1.2), 14), 1.33));
      }
      
      // Add New Pattern Buttons
      addButtons = new DynamicContainer();
      add(addButtons);
      addButtons.add(new AddPatButton("+"));
      
      //addButtons.setAlign(ALIGN_VERTICALLY);
    }
    
    private class MuteToggle extends ToggleLed {
      public MuteToggle() {
        super();
        setSizeFixed(16, 16);
        setColorFixed(color(244, 0, 0));
      }
      public void action() {
        if (track.isMuted()) {
          track.unMute();
        } else {
          track.mute();
        }
      }
      public void render() {
        if (track.isMuted()) {
          press();
        } else {
          release();
        }
        super.render();
      }
    }
    private class SoloToggle extends ToggleLed {
      public SoloToggle() {
        super();
        setSizeFixed(16, 16);
        setColorFixed(color(140, 120, 244));
      }
      public void action() {
        if (isPressed()) {
          midiManager.solo(track);
        } else {
          midiManager.solo(null);
        }
      }
      public void render() {
        if (midiManager.getSolo() == track) {
          press();
        } else {
          release();
        }
        super.render();
      }
    }
    
    private class AddPatButton extends Button {
      public AddPatButton(String s) {
        super(s);
        setTextSize(16);
      }
      public void action() {
        Pattern newPattern = new Pattern();
        track.addPattern(newPattern);
        PatternUI patUI = new PatternUI(newPattern);
        addPattern(patUI);
        patUI.setColorFixed(colMult(colNoise(colSat(patUI.col, 1.2), 14), 1.33));
      }
    }
    
    public ArrayList<PatternUI> getPattern() {
      ArrayList<PatternUI> puis = new ArrayList<PatternUI>();
      for (Element pui : patterns.getChildren()) {
        puis.add((PatternUI) pui);
      }
      return puis;
    }
    public void addPattern(PatternUI patternUI) {
      println("UI: pattern added");
      println("    length "+patternUI.getPattern().getLength());
      patterns.add(patternUI);
      track.addPattern(patternUI.getPattern());
      align();
      shrink();
    }
    public void addPattern(int idx, PatternUI patternUI) {
      println("UI: pattern added");
      println("    length "+patternUI.getPattern().getLength());
      patterns.add(idx, patternUI);
      track.addPattern(idx, patternUI.getPattern());
      align();
      shrink();
    }
    public void removePattern(PatternUI patternUI) {
      patterns.remove(patternUI);
      track.removePattern(patternUI.getPattern());
      align();
      shrink();
    }
    public MyTrack getTrack() { return track; }
    
    public boolean mouseClicked(MouseEvent event) {
      boolean accepted = super.mouseClicked(event);
      selectTrack(track);
      return accepted;
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
        println("drag pane unselect");
        unregisterSelected();
        selectTrack(null);
        setRenderDirty();
      }
      return accepted;
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
      setAlign(ALIGN_ROW + ALIGN_TOP);
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
      println("mouseReleased of patterns container");
      //boolean accepted = super.mouseReleased(event);
      Element dragged = getDragged();
      if (dragged != null && dragged.getClass() == PatternUI.class) {
        // Capture Pattern
        // Find array index correponding to mouse pointer position
        float pointerLocalX = event.getX()-getAbsoluteX();
        float rightBoundary = 0f;
        ArrayList<Element> patterns = getChildren();
        for (int i=0; i<=patterns.size(); i++) {
          if (i==patterns.size() || pointerLocalX < rightBoundary+patterns.get(i).getWidth()/2) {
            // Remove from parent
            ((Container) dragged.getParent()).remove(dragged);
            // Insert element in position
            ((TrackContainer) getParent()).addPattern(i, (PatternUI) dragged);
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
    
    public void setColor(color c) {
      super.setColor(colNoise(c, 50));
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
      
      // Draw tick progress bar
      noStroke();
      fill(0, 32);
      float tx = ((TrackContainer) getParent()).getTrack().getTick()*getScaleX()/midiManager.getPPQ();
      rect(getX(), getY(), tx, getHeight());
      
      unsetRenderDirty();
    }
  }
  
  

  /***************************************************
   ******************   PATTERN_UI   *****************
   ***************************************************/
  class PatternUI extends Element {
    // PatternUI should not be confused with Pattern class
    private final Pattern pattern;
    private long lastClick = 0;

    public PatternUI(Pattern p) {
      super();
      pattern = p;
      setSize(p.getLength()/(float) midiManager.getPPQ(), 64);
    }
    
    public Pattern getPattern() { return pattern; }
    
    public TrackContainer getTrackUI() {
      if (getParent() != null && getParent().getClass() == PatternContainer.class) {
        return (TrackContainer) (getParent().getParent());
      }
      return null;
    }
    
    public float getWidth() { return super.getWidth() * getScaleX(); }
    public float getHeight() { return super.getHeight() * getScaleY(); }
    
    // XXX
    /*public void scaleX(float factor) {
      setX(factor*getX());
      print("scale from "+getWidth()+" to ");
      setSize(factor*getWidth(), getHeight());
      println(getWidth());
    }*/
      
    
    public boolean mouseClicked(MouseEvent event) {
      registerSelected(this);
      println("UI: Pattern selected");
      
      if (System.currentTimeMillis()-lastClick < 200) {
        // Double-click, play pattern
        println("play pattern");
        midiManager.playPattern(pattern);
      }
      lastClick = System.currentTimeMillis();
      
      // Cut pattern in two if CTRL key is down
      if(getTrackUI()!=null && event.isControlDown()) {
        float pointerLocalX = event.getX()-getAbsoluteX();
        int tickCoord = round(pointerLocalX*midiManager.getPPQ()/getScaleX());
        int patternIdx = ((Container) getParent()).getChildren().indexOf(this);
        Pattern[] divided = pattern.divide(tickCoord);
        if (divided[1] != null) {
          PatternUI left = new PatternUI(divided[0]);
          PatternUI right = new PatternUI(divided[1]);
          left.setColorFixed(colNoise(col, 14));
          right.setColorFixed(colNoise(col, 14));
          getTrackUI().addPattern(patternIdx, left);
          getTrackUI().addPattern(patternIdx+1, right);
          getTrackUI().removePattern(this);
        }
      }
      //setRenderDirty();
      return true;
    }
    public boolean mousePressed(MouseEvent event) {
      if (getResized() == null) {      
          // Resizing
          if (event.getX() > getAbsoluteX()+getWidth()-6)
            registerResized(this);
          return true;
      }
      return false;
    }
    public boolean mouseReleased(MouseEvent event) {
      println("UI: Pattern mouseReleased");
      if (getResized() == this) {
        if (event.isShiftDown()) {
          // Stretch notes
          println("UI Pattern: stretch");
          getPattern().stretchTo(midiManager.getPPQ()*round(super.getWidth()));
        } else {
          println("UI PatternUI: size set to "+midiManager.getPPQ()*round(super.getWidth()));
          getPattern().setLength(midiManager.getPPQ()*round(super.getWidth()));
        }
      }
      return false;
    }
    public boolean mouseDragged(MouseEvent event) {
      if (getResized() == this) {
        // Resizing pattern
        float newSize = (mouseX-getAbsoluteX())/getScaleX();
        println("resizing to "+newSize);
        if (event.isShiftDown()) {
          // Stretch notes
          println("streeeetch");
        }
        setSize(newSize, 64);
        if (getTrackUI() != null) {
          ((PatternContainer) getParent()).align();
          getTrackUI().align();
          //getTrackUI().shrink();
        }
        setRenderDirty();
        return true;
      }
      
      // Drag only if no other element is being dragged
      if (getDragged() == null) {
        registerDragged(this);
      }
      if (getDragged() == this) {
        // Mouving pattern around
        if (getParent().getClass() == PatternContainer.class) {
          // Pattern is in a track
          if (event.isShiftDown()) {
            // Copy this pattern (SHIFT key)
            PatternUI copy = new PatternUI(new Pattern(pattern));
            copy.setColorFixed(col);
            registerDragged(copy);
            copy.setX(getAbsoluteX());
            copy.setY(getAbsoluteY());
            centerPane.add(copy);
          } else {
            // Detach from parent TrackContainer
            float x = getAbsoluteX();
            float y = getAbsoluteY();
            getTrackUI().removePattern(this);
            // Add pattern to centerPane
            centerPane.add(this);
            setPos(x-centerPane.getX(), y-centerPane.getY());
          }
        } else if (getParent().getClass() == TracksDragPane.class) {
          // Center on mouse cursor
          setX(mouseX-centerPane.getX()-getWidth()/2);
          setY(mouseY-centerPane.getY()-getHeight()/2);
        }
        setRenderDirty();
      }
      return false;
    }

    public void render() {
      stroke(dark);
      strokeWeight(1);
      fill(col);
      if (getTrackUI()!=null && getSelectedTrack()==getTrackUI().getTrack()) {
        fill(light);
      }
      if (getSelected()==this) {
        // Selected
        fill(lighter);
      } else if (getDragged()==this) {
        fill(lighter);
      }
      rect(getX(), getY(), getWidth(), getHeight());
      
      // Draw notes
      stroke(darker);
      long ppq = midiManager.getPPQ();
      for (MidiNote note : pattern.getNotes()) {
        int pitch = note.getPitch();
        float startX = getX() + note.getStart()*getScaleX()/ppq;
        float endX = getX() + note.getEnd()*getScaleX()/ppq;
        // Crop notes that are after end of pattern
        if (endX > getWidth())
          break;
        line(startX, getY()+64-0.5*pitch, endX, getY()+64-0.5*pitch);
      }
      
      // Draw resize handle
      fill(255, 80);
      noStroke();
      rect(getX()+getWidth()-6, getY(), 6, 64);
      
      unsetRenderDirty();
    }
  }
}
