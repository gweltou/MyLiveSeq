

/***************************************************
 ***************** PATTERN WINDOW ******************
 ***************************************************/
class PatternWindow extends Window {
  private final PatternToolBar toolBar;
  private final NotesContainer notesContainer;
  private Pattern pattern;
  private Affine2 transform = new Affine2();
  private float pointerOffset; // Relative position of mouse cursor from note start
  
  public PatternWindow(UI ui) {
    super(ui);
    setWindow(this);
    transform.scale(16, 5);
    setColor(color(127));
    
    notesContainer = new NotesContainer();
    notesContainer.setSize(width, height);
    add(notesContainer);
    
    toolBar = new PatternToolBar();
    add(toolBar);

    BottomBar bottomBar = new PatternBottomBar();
    add(bottomBar);
    
    notesContainer.setY(toolBar.getHeight()+1.6);
    notesContainer.setSizeFixed(width, height-toolBar.getHeight()-bottomBar.getHeight()-2);
    notesContainer.setRenderDirty(); //XXX
  }
  
  public void setPattern(Pattern pattern) {
    midiManager.stopAndRewind();
    midiManager.playPattern(pattern);
    this.pattern = pattern;
    notesContainer.clear();
    for (MidiNote midiNote : pattern.getNotes()) {
      notesContainer.add(new NoteUI(midiNote));
    }
  }
  
  public void render() {
    if (notesContainer.isRenderDirty()) {
      super.render();
    } else {
      super.renderDirty();
    }
  }
  
  public boolean keyPressed(KeyEvent event) {
    // Zoom In/Out
    if (key=='a') {
      Affine2 inverted = new Affine2(transform).inv();
      PVector center = new PVector(mouseX, mouseY-notesContainer.getY());
      inverted.applyTo(center);
      transform.translate(center.x, center.y).scale(1.3, 1.3).translate(-center.x, -center.y);
      notesContainer.setRenderDirty();
    } else if (key=='z') {
      Affine2 inverted = new Affine2(transform).inv();
      PVector center = new PVector(mouseX, mouseY-notesContainer.getY());
      inverted.applyTo(center);
      transform.translate(center.x, center.y).scale(0.8, 0.8).translate(-center.x, -center.y);
      notesContainer.setRenderDirty();
    } else if (event.getKey() == DELETE) {
      // Delete note if selected
      if (getSelected()!=null && getSelected().getClass()==NoteUI.class && getDragged()==null) {
        notesContainer.getChildren().remove(getSelected());
        pattern.remove(((NoteUI) getSelected()).note);
        unregisterSelected();
        notesContainer.setRenderDirty();
      }
    }
    return false;
  }
  
  
  /***************************************************
  **************    NotesContainer    ****************
  ***************************************************/
  private class NotesContainer extends Container {
    public NotesContainer() { super(); }
    
    public boolean mouseClicked(MouseEvent event) {
      boolean accepted = false;
      Affine2 unproject = new Affine2(transform).inv();
      PVector pointer = new PVector(mouseX, mouseY-getY());
      unproject.applyTo(pointer);
      println("click ", pointer.x, pointer.y);
      for (int i=0; i<getChildren().size(); i++) {
        if (getChildren().get(i).containsPoint(pointer.x, pointer.y)) {
          accepted = getChildren().get(i).mouseClicked(event);
          if (accepted) break;
        }
      }
      return accepted;
    }
    public boolean mouseDragged(MouseEvent event) {
      // Move world if right mouse drag
      if (event.getButton() == RIGHT) {
        float dx = mouseX - pmouseX;
        float dy = mouseY - pmouseY;
        transform.translate(dx/transform.m00, dy/transform.m11);
        setRenderDirty();
        return false;
      } else {
        boolean accepted = false;
        Affine2 unproject = new Affine2(transform).inv();
        PVector pointer = new PVector(mouseX, mouseY-getY());
        unproject.applyTo(pointer);
        for (int i=0; i<getChildren().size(); i++) {
          if (getChildren().get(i).containsPoint(pointer.x, pointer.y)) {
            accepted = getChildren().get(i).mouseDragged(event);
            if (accepted) break;
          }
        }
        return accepted;
      }
    }
    
    public void render() {
      noStroke();
      fill(250);
      rect(getX(), getY(), getWidth(), getHeight());
      super.render();
      
      // Play head
      stroke(0, 255, 0, 128);
      strokeWeight(2);
      float patternTick = (float) midiManager.getPatternTick()*transform.m00/midiManager.getPPQ();
      patternTick += transform.m02;
      line(patternTick, getY(), patternTick, getY()+getHeight());
    }
  }
  
  
  
  /***************************************************
  *******************  NOTE UI  **********************
  ***************************************************/
  private class NoteUI extends Element {
    private MidiNote note;
    //private PVector viewPos;
    
    public NoteUI(MidiNote note) {
      super();
      this.note = note;
      setX((float) note.getStart()/midiManager.getPPQ());
      setY(128-note.getPitch());
      setSize((float) note.getDuration()/midiManager.getPPQ(), 1);
    }
    
    public void render() {
      noStroke();
      if (getSelected() == this) {
        fill(lighter);
      } else {
        fill(col);
      }
      PVector pos = new PVector(getX(), getY());
      transform.applyTo(pos);
      rect(pos.x, pos.y, getWidth()*transform.m00, getHeight()*transform.m11);
    }
    
    public boolean mouseClicked(MouseEvent event) {
      println("note clicked");
      registerSelected(this);
      setRenderDirty();
      return true;
    }
    
    public boolean mouseDragged(MouseEvent event) {
      if (getDragged() == null) {
        registerDragged(this);
        registerSelected(this);
        
        // Keep note's relative position to mouse cursor
        Affine2 unproject = new Affine2(transform).inv();
        PVector pointer = new PVector(mouseX, mouseY-getParent().getY());
        unproject.applyTo(pointer);
        pointerOffset = pointer.x - getX();
        println("offset ", pointerOffset);
      }
      if (getDragged() == this) {
        // event coordinates can't be trusted because event can be launched
        // from the window element or the notesContainer element
        Affine2 unproject = new Affine2(transform).inv();
        PVector pointer = new PVector(mouseX, mouseY-getParent().getY());
        unproject.applyTo(pointer);
        
        pointer.x -= pointerOffset;
        // Lock x position to midi resolution grid
        float subQuarterPos = pointer.x - floor(pointer.x);
        subQuarterPos = (float) round(subQuarterPos * midiManager.getPPQ()) / midiManager.getPPQ();
        setX(floor(pointer.x) + subQuarterPos);
        setY(floor(pointer.y));
      }
      setRenderDirty();
      return true;
    }
    
    public boolean mouseReleased(MouseEvent event) {
      println("note released");
      println("start before: ", note.getStart());
      note.setStart(round(getX()*midiManager.getPPQ()));
      println("start", note.getStart());
      note.setPitch(128 - round(getY() / getScaleY()));
      pattern.sort();
      return true;
    }
  }
  

  /***************************************************
   ********************* TOOL BAR ********************
   ***************************************************/
  class PatternToolBar extends ToolBar {
    
    public PatternToolBar() {
      super();
      setSizeFixed(width, getHeight());
      
      add(new ButtonRec());
    }
    
    private class ButtonRec extends Button {
      public ButtonRec() {
        super("REC");
      }
      public void action() {
        midiManager.startRecording(pattern);
      }
    }
    /*
    private class OffsetButton extends Button {
      // Change pattern starting position
    }
    
    private class ButtonEdit extends Button {
      public ButtonEdit() {
        super("Edit");
      }
    }
    */
  }
  
  
  /***************************************************
   *************** TRACKS BOTTOM BAR *****************
   ***************************************************/
  class PatternBottomBar extends BottomBar {
    public PatternBottomBar() {
      super();
      center.setSpacing(14);
      center.setAlign(ALIGN_ROW);
      Button acceptBtn = new AcceptButton();
      center.add(acceptBtn);
      Button cancelBtn = new CancelButton();
      center.add(cancelBtn);
      
      add(center);
      
      setSize(width, center.getHeight()+2*getPadding());
      setPos(0, height-getHeight());
      align();
    }
    
    private class AcceptButton extends Button {
      public AcceptButton() {
        super("OK");
      }
      public void action() {
        tracksWindow.show();
      }
    }
    private class CancelButton extends Button {
      public CancelButton() {
        super("Cancel");
      }
      public void action() {
        tracksWindow.show();
      }
    }
  }
}
