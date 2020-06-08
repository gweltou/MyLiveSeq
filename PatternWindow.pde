

/***************************************************
 ***************** PATTERN WINDOW ******************
 ***************************************************/
class PatternWindow extends Window {
  private final PatternToolBar toolBar;
  private final PatternDragPane centerPane;
  private Pattern pattern;
  private Affine2 transform = new Affine2();
  
  public PatternWindow(UI ui) {
    super(ui);
    setWindow(this);
    transform.scale(8, 5);
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
    midiManager.stopAndRewind();
    midiManager.playPattern(pattern);
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
    if (key=='a') {
      Affine2 inverted = new Affine2(transform).inv();
      PVector center = new PVector(mouseX, mouseY);
      inverted.applyTo(center);
      transform.translate(center.x, center.y).scale(1.3, 1.3).translate(-center.x, -center.y);
      centerPane.setRenderDirty();
    } else if (key=='z') {
      Affine2 inverted = new Affine2(transform).inv();
      PVector center = new PVector(mouseX, mouseY);
      inverted.applyTo(center);
      transform.translate(center.x, center.y).scale(0.8, 0.8).translate(-center.x, -center.y);
      centerPane.setRenderDirty();
    }
    return false;
  }
  
  private class PatternDragPane extends DragPane {
    public PatternDragPane() { super(); }
    
    public boolean mouseDragged(MouseEvent event) {
      // Move world if right mouse drag
      if (event.getButton() == RIGHT) {
         float dx = mouseX - pmouseX;
         float dy = mouseY - pmouseY;
         transform.translate(dx/transform.m00, dy/transform.m11);
      }
      return false;
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
    //private PVector viewPos;
    
    public NoteUI(MidiNote note) {
      super();
      this.note = note;
      setX(note.getStart()/midiManager.getPPQ());
      setY(128-note.getPitch());
      setSize((float) note.getDuration()/midiManager.getPPQ(), 1);
    }
    
    public void render() {
      noStroke();
      fill(col);
      //println(getX() + " " + getY() + " " + getWidth());
      PVector pos = new PVector(getX(), getY());
      transform.applyTo(pos);
      rect(pos.x, pos.y, getWidth()*transform.m00, getHeight()*transform.m11);
    }
    
    public boolean mouseDragged(MouseEvent event) {
      if (getDragged() == null) {
        registerDragged(this);
      }
      if (getDragged() == this) {
        println("note dragged");
      }
      float dx = mouseX - pmouseX;
      float dy = mouseY - pmouseY;
      setX(getX() + dx);
      setY(getY() + dy);
      return true;
    }
    public boolean mouseReleased(MouseEvent event) {
      println("note released");
      println("before: " + note.getPitch());
      int newPitch = 128 - round(getY() / getScaleY());
      println("after: " + newPitch);
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
