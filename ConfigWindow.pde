
/***************************************************
 ****************** CONFIG WINDOW ******************
 ***************************************************/
class ConfigWindow extends Window {
  //private final ConfigToolBar toolBar;
  private final DragPane centerPane;
  private DeviceList inDevList, outDevList;

  public ConfigWindow(UI ui) {
    super(ui);
    
    centerPane = new DragPane();
    centerPane.setSize(width, height);
    add(centerPane);
    
    inDevList = new DeviceList();
    centerPane.add(inDevList);
    inDevList.setSpacing(3);
    inDevList.setPos(20, 30);
    ArrayList<MidiDevice> inDevices = midiManager.getTransmitters();
    for (MidiDevice device : inDevices) {
      inDevList.add(new DeviceButton(device));
    }
    inDevList.setAlign(ALIGN_COLUMN + ALIGN_RIGHT);
    
    outDevList = new DeviceList();
    centerPane.add(outDevList);
    outDevList.setSpacing(3);
    outDevList.setPos(inDevList.getX()+inDevList.getWidth()+5, 30);
    ArrayList<MidiDevice> outDevices = midiManager.getReceivers();
    for (MidiDevice device : outDevices) {
      outDevList.add(new DeviceButton(device));
    }
    outDevList.setAlign(ALIGN_COLUMN);
    
    inDevList.select(midiManager.getInputDevice());
    outDevList.select(midiManager.getOutputDevice());

    BottomBar bottomBar = new ConfigBottomBar();
    add(bottomBar);
  }
  
  
  /***************************************************
   ****************  DEVICE BUTTON  ******************
   ***************************************************/
  class DeviceButton extends ToggleButton {
    private MidiDevice device;
    
    public DeviceButton(MidiDevice dev) {
      super(dev.getDeviceInfo().getDescription());
      device = dev;
    }
    
    public MidiDevice getDevice() {
      return device;
    }
    
    public boolean mouseClicked(MouseEvent event) {
      ((DeviceList) getParent()).select(device);
      return true;
    }
  }
  
  /***************************************************
   ******************  DEVICE LIST  ******************
   ***************************************************/
  class DeviceList extends DynamicContainer {
    private MidiDevice selected = null;
    
    public DeviceList() {
      super();
    }
    
    public MidiDevice getSelected() { return selected; }
    public void select(MidiDevice dev) {
      if (dev == null)
        return;
      selected = dev;
      for (Element child : getChildren()) {
        DeviceButton btn = (DeviceButton) child;
        if (btn.getDevice() == selected)
          btn.toggle();
        else
          btn.unToggle();
      }
    }
  }
  
  
  
  /***************************************************
   ********************* TOOL BAR ********************
   ***************************************************/
  class ConfigToolBar extends ToolBar {
    public ConfigToolBar() {
      super();
      setSize(width, getHeight());
    }

    private class ButtonEdit extends Button {
      public ButtonEdit() {
        super("Edit");
      }
    }
  }


  /***************************************************
   *************** CONFIG BOTTOM BAR *****************
   ***************************************************/
  class ConfigBottomBar extends BottomBar {
    public ConfigBottomBar() {
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
        super("Save");
      }
      public void action() {
        if (inDevList.getSelected() != null) {
          int n = midiManager.getTransmitters().indexOf(inDevList.getSelected());
          midiManager.setTransmitter(n);
        }
        if (outDevList.getSelected() != null) {
          int n = midiManager.getReceivers().indexOf(outDevList.getSelected());
          midiManager.setReceiver(n);
        }
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
