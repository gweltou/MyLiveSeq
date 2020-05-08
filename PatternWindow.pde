
/***************************************************
 ***************** PATTERN WINDOW ******************
 ***************************************************/
class PatternWindow extends Window {
  private final ToolBar toolBar;
  //private final TracksDragPane centerPane;
  
  //centerPane = new TracksDragPane();
  //centerPane.setSize(width, height);
  //add(centerPane);
  
  public PatternWindow(UI ui) {
    super(ui);
    
    toolBar = new ToolBar();
    add(toolBar);

    BottomBar bottomBar = new BottomBar();
    add(bottomBar);
  }
  
  /***************************************************
   ********************* TOOL BAR ********************
   ***************************************************/
  class ToolBar extends DynamicContainer {
    
    public ToolBar() {
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
    
    private class ButtonEdit extends Button {
      public ButtonEdit() {
        super("Edit");
      }
    }
  }
  
  
  /***************************************************
   ******************* BOTTOM BAR ********************
   ***************************************************/
  class BottomBar extends Container {
    DynamicContainer center = new DynamicContainer();

    public BottomBar() {
      setColor(color(180));
      setPadding(3);

      center.setSpacing(12);
      center.setAlign(ALIGN_ROW);
      Button acceptBtn = new AcceptButton();
      center.add(acceptBtn);
      Button cancelBtn = new CancelButton();
      center.add(cancelBtn);
      
      add(center);
      
      setSize(width, center.getHeight()+2*getPadding());
      setPos(0, height-getHeight());
      setAlign(ALIGN_CENTER);
      center.setY(center.getY()-getPadding());  // CHEAP TRICK !!!
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
