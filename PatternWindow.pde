
/***************************************************
 ***************** PATTERN WINDOW ******************
 ***************************************************/
class PatternWindow extends Window {
  private final PatternToolBar toolBar;
  //private final TracksDragPane centerPane;
  
  //centerPane = new TracksDragPane();
  //centerPane.setSize(width, height);
  //add(centerPane);
  
  public PatternWindow(UI ui) {
    super(ui);
    
    toolBar = new PatternToolBar();
    add(toolBar);

    BottomBar bottomBar = new PatternBottomBar();
    add(bottomBar);
  }
  
  /***************************************************
   ********************* TOOL BAR ********************
   ***************************************************/
  class PatternToolBar extends ToolBar {
    
    public PatternToolBar() {
      super();
      setSize(width, getHeight());
    }
    
    private class offsetButton extends Button {
      
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
