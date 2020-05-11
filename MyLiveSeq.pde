MidiManager midiManager;
UI ui = new UI();
TracksWindow tracksWindow;

color bgcolor = color(245);


void setup() {
  size(900, 600);
  rectMode(CORNER);
  ellipseMode(CORNER);
  
  midiManager = new MidiManager();
  midiManager.start();
  
  tracksWindow = new TracksWindow(ui);
  
  tracksWindow.show();
}


void draw() {
  background(bgcolor);
  ui.render();
}


//
// EVENTS
//
void keyPressed(KeyEvent event) {
  ui.keyPressed(event);
}
void mousePressed(MouseEvent event) {
  ui.mousePressed(event);
}
void mouseReleased(MouseEvent event) {
  ui.mouseReleased(event);
}
void mouseClicked(MouseEvent event) {
  ui.mouseClicked(event);
}
void mouseDragged(MouseEvent event) {
  ui.mouseDragged(event);
}
