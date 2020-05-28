

/***************************************************
 ***************** PATTERN WINDOW ******************
 ***************************************************/
class PatternWindow extends Window {
  private final PatternToolBar toolBar;
  private final PatternDragPane centerPane;
  private Pattern pattern;
  
  //private final TracksDragPane centerPane;
  
  //centerPane = new TracksDragPane();
  //centerPane.setSize(width, height);
  //add(centerPane);
  
  public PatternWindow(UI ui) {
    super(ui);
    setWindow(this);
    setScaleY(5);
    setColor(color(127));
    
    centerPane = new PatternDragPane();
    centerPane.setSize(width, height);
    add(centerPane);
    
    toolBar = new PatternToolBar();
    add(toolBar);

    BottomBar bottomBar = new PatternBottomBar();
    add(bottomBar);
    
    centerPane.setY(toolBar.getHeight()+1.6);
    centerPane.setSizeFixed(width, height-toolBar.getHeight()-bottomBar.getHeight()-2);
    centerPane.setRenderDirty(); //XXX
  }
  
  public void setPattern(Pattern pattern) {
    this.pattern = pattern;
    centerPane.clear();
    for (MidiNote midiNote : pattern.getNotes()) {
      centerPane.add(new NoteUI(midiNote));
    }
  }
  
  public void render() {
    if (centerPane.isRenderDirty()) {
      super.render();
    } else {
      super.renderDirty();
    }
  }
  
  public boolean keyPressed(KeyEvent event) {
    // Zoom In/Out
    if (event.getKey() == 'a') {
      centerPane.translate(-width/2, 0);
      centerPane.scaleX(1.5);
      centerPane.translate(width/2, 0);
      //tracksContainer.refresh();
      centerPane.setRenderDirty();
    } else if (event.getKey() == 'z') {
      centerPane.translate(-width/2, 0);
      centerPane.scaleX(0.5);
      centerPane.translate(width/2, 0);
      centerPane.setRenderDirty();
    }
    return false;
  }
  
  private class PatternDragPane extends DragPane {
    private float scaleX = 1;
    
    public PatternDragPane() { super(); }
    
    public void scaleX(float factor) {
      scaleX *= factor;
      for (Element child : getChildren()) {
        ((NoteUI) child).scaleX(factor);
      }
    }
    
    public void render() {
      super.render();
    }
  }
  
  
  
  /***************************************************
  *******************  NOTE UI  **********************
  ***************************************************/
  private class NoteUI extends Element {
    private MidiNote note;
    
    public NoteUI(MidiNote note) {
      super();
      this.note = note;
      setX(note.getStart()/midiManager.getPPQ());
      setY((128-note.getPitch())*getScaleY());
      setSize((float) note.getDuration()/midiManager.getPPQ(), 1);
      scaleX(8);
    }
    
    public void scaleX(float factor) {
      setX(factor*getX());
      setSize(factor*getWidth(), getHeight());
    }
    
    public void render() {
      strokeWeight(4);
      stroke(0, 120);
      //println(getX() + " " + getY() + " " + getWidth());
      line(getX(), getY(), getX()+getWidth(), getY());
    }
  }
  

  /***************************************************
   ********************* TOOL BAR ********************
   ***************************************************/
  class PatternToolBar extends ToolBar {
    
    public PatternToolBar() {
      super();
      setSizeFixed(width, getHeight());
    }
    
    private class OffsetButton extends Button {
      
    }
    
    private class ButtonEdit extends Button {
      public ButtonEdit() {
        super("Edit");
      }
    }
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
