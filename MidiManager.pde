
import javax.sound.midi.*;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.PriorityQueue;
import java.util.logging.ConsoleHandler;
import java.util.logging.Level;
import java.util.logging.Logger;


public class MidiNote {
  private final int pitch;
  private final int velocity;
  private final long start;
  private final long duration;

  public MidiNote(int pitch, int velocity, long start, long duration) {
    this.pitch = pitch;
    this.velocity = velocity;
    this.start = start;
    this.duration = duration;
  }

  public int getPitch() { 
    return pitch;
  }
  public int getVelocity() { 
    return velocity;
  }
  public long getStart() { 
    return start;
  }
  public long getEnd() { 
    return start+duration;
  }
  public long getDuration() { 
    return duration;
  }
}



public class Pattern {
  /*
     *  TimeStamps for Midi events are expressed in beats relative to the pattern start time
   *  Un seul pattern peut être enregistré/édité à la fois
   *  On définit d'abord le nombre de beats dans le pattern,
   *  la longueur du pattern pourra être modifié par la suite
   *  (en laissant l'extension vide ou en copiant les notes du début du pattern)
   *  ~~ Toute note du pattern doit se terminer à la fin du pattern au plus tard
   *
   *  Paramètres:
   *      Gamme
   *      Filter out CC
   */
  private final ArrayList<MidiEvent> midiEvents = new ArrayList();
  private final ArrayList<MidiNote> midiNotes = new ArrayList();
  private long nTicks;
  private int nRepeat = 1;

  public Pattern() {
    this(24*32);
  }
  public Pattern(Pattern other) {
    setLength(other.getLength());
    midiNotes.addAll(other.getNotes());
    midiEvents.addAll(other.getEvents());
  }
  public Pattern(long ticks) {
    setLength(ticks);
  }

  public void setLength(long ticks) { 
    this.nTicks = ticks;
  }
  public long getLength() {
    return nTicks;
  }
  public long getRepeat() { 
    return nRepeat;
  }
  public void trimLength() {
    println("trim");
    nTicks = 0;
    for (MidiNote note : midiNotes) {
      if (note.getEnd() > nTicks) {
        nTicks = note.getEnd();
      }
    }
  }

  public ArrayList<MidiEvent> getEvents() { 
    return midiEvents;
  }
  public void addEvent(MidiEvent event) { 
    midiEvents.add(event);
  }

  public void addNote(MidiNote note) { 
    midiNotes.add(note);
  }
  public void addNotes(ArrayList<MidiNote> notes) { 
    midiNotes.addAll(notes);
  }
  public ArrayList<MidiNote> getNotes() {
    return midiNotes;
  }

  public Pattern[] divide(long ticks) {
    Pattern[] divided = new Pattern[2];
    if (ticks >= getLength() || ticks <= 0) {
      // ticks coordinate out of bounds
      divided[0] = this;
      return divided;
    }
    Pattern left = new Pattern();
    left.setLength(ticks);
    Pattern right = new Pattern();
    right.setLength(getLength()-ticks);
    for (MidiNote note : getNotes()) {
      int pitch = note.getPitch();
      int vel = note.getVelocity();
      if (note.getStart() < ticks) {
        // Add to left pattern and split last note
        if (note.getEnd() >= ticks) {
          // First part to the left
          left.addNote(new MidiNote(pitch, vel, note.getStart(), ticks-note.getStart()));
          // Second part to the right
          right.addNote(new MidiNote(pitch, vel, 0, note.getEnd()-ticks));
        } else {
          left.addNote(note);
        }
      } else {
        // Add to right pattern and offset by -ticks
        right.addNote(new MidiNote(pitch, vel, note.getStart()-ticks, note.getDuration()));
      }
    }
    divided[0] = left;
    divided[1] = right;
    return divided;
  }
}



public class MyTrack {
  /*
     *  Paramètres :
   *      Mute on/off
   *      Midi Channel
   *      Transpose Octave
   *      Transpose semi-tones
   */
  private final int midiChannel;
  private final ArrayList<Pattern> patterns = new ArrayList();
  private int patternIndex;
  private int patternRepeatCount;


  public MyTrack() {
    midiChannel = 0;
    patternIndex = 0;
    patternRepeatCount = 0;
  }

  public void addPattern(Pattern pattern) {
    patterns.add(pattern);
  }

  public ArrayList<Pattern> getPatterns() {
    return patterns;
  }

  public Pattern nextPattern() {
    // No more patterns to play
    if (patternIndex >= patterns.size())
      return null;

    Pattern next = patterns.get(patternIndex);
    if (patternRepeatCount < next.getRepeat()) {
      patternRepeatCount++;
      return next;
    }

    patternIndex++;
    return next;
  }
}



public class MidiManager extends Thread {
  private final PriorityQueue<MidiEvent> eventQueue;
  private final ArrayList<MyTrack> tracks = new ArrayList();
  private final ArrayList<MidiDevice> transmitters = new ArrayList();
  private final ArrayList<MidiDevice> receivers = new ArrayList();
  private MidiDevice inputDevice, outputDevice;
  private MyMidiReceiver midiIn;
  private Receiver midiOut;
  private boolean stop;    // MidiManager stops when running is set to false
  private final int[] activeNotesVel;
  private final long[] activeNotesTime;
  public boolean running;
  public boolean recording;
  private Pattern pattern;
  private boolean patternPlaying                  = false;
  private long patternStartTime;
  private long patternLength;
  private long tickDuration;
  private long lastTickTime;
  private long localTicks;
  private long lastLocalTickTime;
  private long localTickDuration;
  private final int tickResolution = 1; // Ticks default resolution is multiplied by this number
  private boolean clockSlave;
  private float bpm;

  public MidiManager() {
    activeNotesVel = new int[128];
    Arrays.fill(activeNotesVel, 0);
    activeNotesTime = new long[128];
    Arrays.fill(activeNotesTime, 0);
    eventQueue = new PriorityQueue(32, new EventComparator());
    inputDevice = null;
    outputDevice = null;
    midiIn = null;
    midiOut = null;
    int dev_i = findDevice(getTransmitters(), "beatstep");
    setTransmitter(Math.max(dev_i, 0));
    setReceiver(0);

    clockSlave = false;
    running = false;
    recording = false;
    setBpm(120);
    //play();
  }

  class EventComparator implements Comparator<MidiEvent> {
    @Override
      public int compare(MidiEvent o1, MidiEvent o2) {
      return Long.compare(o1.getTick(), o2.getTick());
    }
  }

  public MidiDevice getInputDevice() { 
    return inputDevice;
  }
  public MidiDevice getOutputDevice() { 
    return outputDevice;
  }

  public ArrayList<MidiDevice> getTransmitters() {
    transmitters.clear();
    for (MidiDevice.Info info : MidiSystem.getMidiDeviceInfo()) {
      try {
        MidiDevice dev = MidiSystem.getMidiDevice(info);
        int numConnections = dev.getMaxTransmitters();
        if (numConnections > 0 || numConnections == -1) {
          // -1 means an unlimited number of connections are available for the device
          transmitters.add(dev);
        }
      } 
      catch (MidiUnavailableException e) {
        println("Périphérique Midi non trouvé");
      }
    }
    return transmitters;
  }

  public ArrayList<MidiDevice> getReceivers() {
    receivers.clear();
    for (MidiDevice.Info info : MidiSystem.getMidiDeviceInfo()) {
      try {
        MidiDevice dev = MidiSystem.getMidiDevice(info);
        int numConnections = dev.getMaxReceivers();
        if (numConnections > 0 || numConnections == -1) {
          // -1 means an unlimited number of connections is available for the device
          receivers.add(dev);
        }
      } 
      catch (MidiUnavailableException e) {
        println("Périphérique Midi non trouvé");
      }
    }
    return receivers;
  }

  public int findDevice(ArrayList<MidiDevice> devices, String desc) {
    for (int i=0; i<devices.size(); i++) {
      String devDesc = devices.get(i).getDeviceInfo().getDescription().toLowerCase();
      if (devDesc.contains(desc.toLowerCase())) {
        return i;
      }
    }
    return -1;
  }

  class MyMidiReceiver implements Receiver {
    private final MidiEvent[] readBuffer;
    private int readBufferIndex;

    public MyMidiReceiver() {
      readBuffer = new MidiEvent[8];
      readBufferIndex = 0;
    }

    @Override
      public void send(MidiMessage message, long timeStamp) {
      if (message.getStatus() == ShortMessage.TIMING_CLOCK) {
        // Ignore clock timing messages for now
      } else if (readBufferIndex < readBuffer.length) {
        readBuffer[readBufferIndex++] = new MidiEvent(message, localTicks);
      }
    }

    @Override
      public void close() {
    }

    public MidiEvent[] getEvents() {
      if (readBufferIndex > 0) {
        //MyMidiEvent[] newEvents = new MyMidiEvent[readBufferIndex];
        MidiEvent[] newEvents = Arrays.copyOf(readBuffer, readBufferIndex);
        readBufferIndex = 0;
        return newEvents;
      }
      return null;
    }
  }

  public void setTransmitter(int input_device) {
    if (input_device == -1)
      return;
    if (transmitters.isEmpty())
      getTransmitters();

    if (inputDevice != null)
      inputDevice.close();

    try {
      inputDevice = transmitters.get(input_device);
      inputDevice.open();
      midiIn = new MyMidiReceiver();
      inputDevice.getTransmitter().setReceiver(midiIn);
      String desc = inputDevice.getDeviceInfo().getDescription();
      println("Périphérique d'entrée Midi ouvert (" + desc + ")");
    } 
    catch (MidiUnavailableException e) {
      println("Impossible d'oubrir le périphérique d'entrée Midi");
    }
  }

  public void setReceiver(int output_device) {
    if (output_device == -1)
      return;
    if (receivers.isEmpty())
      getReceivers();

    if (outputDevice != null)
      outputDevice.close();

    try {
      outputDevice = receivers.get(output_device);
      outputDevice.open();
      midiOut = outputDevice.getReceiver();
      String desc = outputDevice.getDeviceInfo().getDescription();
      println("Périphérique de sortie Midi ouvert (" + desc + ")");
    } 
    catch (MidiUnavailableException e) {
      println("Impossible d'ouvrir le périphérique de sortie Midi");
    }
  }

  public void playNote(int channel, int pitch, int velocity, float duration) {
    try {
      ShortMessage noteOn = new ShortMessage(ShortMessage.NOTE_ON, channel, pitch, velocity);
      ShortMessage noteOff = new ShortMessage(ShortMessage.NOTE_OFF, channel, pitch, 0);
      eventQueue.add(new MidiEvent(noteOn, localTicks));
      long ticks = Math.round(duration * 24 * tickResolution);
      eventQueue.add(new MidiEvent(noteOff, localTicks+ticks));
    } 
    catch (InvalidMidiDataException e) {
      System.out.println("Invalid Midi Data");
    }
  }

  public void play() {
    println("Playing started");
    long now = System.currentTimeMillis();
    lastTickTime = now;
    lastLocalTickTime = now;
    running = true;
  }
  public void playStop() {
    println("Playing stopped");
  }

  public void loadPattern(Pattern pattern) {
    this.pattern = pattern;
    patternLength = pattern.getLength() * 24 * tickResolution;
  }

  public void playPattern() {
    patternStartTime = localTicks;
    patternPlaying = true;
    running = true;
    println("Pattern loop started");
  }

  public long getPatternTime() { 
    return localTicks-patternStartTime;
  }

  public boolean isRunning() { 
    return running;
  }

  public void startRecording(Pattern pattern) {
    if (isRecording()) {
    } else {
      println("Recording started");
      this.pattern = pattern;
      recording = true;
      Arrays.fill(activeNotesVel, 0);
    }
  }

  public boolean isRecording() { 
    return recording;
  }

  public void setBpm(float newBpm) {
    bpm = newBpm;
    tickDuration = Math.round(60000/(24 * bpm));   // 24 ticks per quarter-note
    localTickDuration = Math.round(60000/(tickResolution * 24 * bpm));
  }

  public void update() {
    // Read Midi Events from midiIn
    MidiEvent[] newEvents = (midiIn == null) ? null : midiIn.getEvents();

    // Send midiIn events to midiOut
    if (midiOut != null) {
      if (newEvents != null) {
        for (MidiEvent event : newEvents) {
          midiOut.send(event.getMessage(), -1);
        }
      }
    }

    // Clock is ticking
    if (isRunning()) {
      if (!clockSlave) {
        long now = System.currentTimeMillis();
        // Update local ticks (may have a greater resolution that default Midi ticks)
        if (now - lastLocalTickTime >= localTickDuration) {
          localTicks += 1;
          lastLocalTickTime += localTickDuration;
        }
        if ((midiOut != null) && (now - lastTickTime > tickDuration)) {
          // Send clock tick to external hardware/software
          try {
            ShortMessage tickMessage = new ShortMessage(ShortMessage.TIMING_CLOCK);
            midiOut.send(tickMessage, -1);
          } 
          catch (InvalidMidiDataException ignored) {
          }
          lastTickTime += tickDuration;
        }
      }

      // Pattern Looping mode
      if (patternPlaying) {
        // Loop if end of pattern reached
        if (localTicks >= patternStartTime+patternLength) {
          // Turn off remaining active notes if recording
          if (isRecording()) {
            for (int i=0; i<128; i++) {
              if (activeNotesVel[i] > 0) {
                long noteStartTime = activeNotesTime[i];
                long start = noteStartTime - patternStartTime;
                long duration = localTicks - noteStartTime;
                pattern.addNote(new MidiNote(i, activeNotesVel[i], start, duration));
                activeNotesVel[i] = 0;
                try {
                  ShortMessage message = new ShortMessage(ShortMessage.NOTE_OFF, i, 0);
                  pattern.addEvent(new MidiEvent(message, patternLength));
                } 
                catch (InvalidMidiDataException ignored) {
                }
              }
            }
          }
          // Load pattern notes in eventQueue
          for (MidiEvent midiEvent : pattern.getEvents()) {
            eventQueue.add(new MidiEvent(midiEvent.getMessage(), midiEvent.getTick()+localTicks));
          }
          patternStartTime = localTicks;
        }

        // Record events to current pattern
        if (isRecording() && newEvents != null) {
          for (MidiEvent event : newEvents) {
            ShortMessage message = (ShortMessage) event.getMessage(); // Maybe clone message

            if (message.getCommand() == ShortMessage.NOTE_ON) {
              // Register note start time
              activeNotesTime[message.getData1()] = event.getTick();
              activeNotesVel[message.getData1()] = message.getData2();
              pattern.addEvent(new MidiEvent(message, event.getTick()-patternStartTime));
            } else if (message.getCommand() == ShortMessage.NOTE_OFF) {
              int pitch = message.getData1();
              int velocity = activeNotesVel[pitch];
              if (velocity > 0) {
                long noteStartTime = activeNotesTime[pitch];
                long start = noteStartTime - patternStartTime;
                long duration = localTicks - noteStartTime;
                pattern.addNote(new MidiNote(pitch, velocity, start, duration));
                activeNotesVel[pitch] = 0;
                pattern.addEvent(new MidiEvent(message, event.getTick()-patternStartTime));
              }
            }
            // We could make another condition to include other type of message in the pattern
          }
        }
      }

      // Send queued Midi events to midiOut
      while (!eventQueue.isEmpty() && eventQueue.peek().getTick() <= localTicks) {
        midiOut.send(eventQueue.poll().getMessage(), -1);
      }
    }
  }

  public void run () {
    println("Midi manager started...");
    stop = false;
    while (!stop) {
      update();
      try {
        Thread.sleep(2L);
      } 
      catch (InterruptedException ignored) {
      }
    }

    // Close Midi ports
    if (outputDevice != null)
      outputDevice.close();
    if (inputDevice != null)
      inputDevice.close();
  }

  public void doStop() {
    stop = true;
  }

  //public void saveToFile(File outputFile) {
  //    Sequence sequence;
  //    try {
  //        sequence = new Sequence(Sequence.PPQ, 1);
  //        Track track = sequence.createTrack();

  //        /* Now we just save the Sequence to the file we specified.
  //           The '0' (second parameter) means saving as SMF type 0.
  //           Since we have only one Track, this is actually the only option
  //            (type 1 is for multiple tracks).
  //    */
  //        MidiSystem.write(sequence, 0, outputFile);
  //    } catch (IOException e) {
  //        e.printStackTrace();
  //        System.exit(1);
  //    }
  //}


  public ArrayList<MidiNote>[] parseEvents(Track track) {
    ArrayList<MidiNote>[] notes = new ArrayList[16];
    long[][] notesOn = new long[128][16];
    for (int i=0; i<16; i++) {
      notes[i] = new ArrayList();
      Arrays.fill(notesOn[i], -1);
    }

    for (int i=0; i<track.size(); i++) {
      MidiEvent event = track.get(i);
      int status = event.getMessage().getStatus();
      if (status == ShortMessage.NOTE_ON || status == ShortMessage.NOTE_OFF) {
        ShortMessage message = (ShortMessage) event.getMessage();
        int command = message.getCommand();
        int channel = message.getChannel();
        if (command == ShortMessage.NOTE_ON) {
          int pitch = message.getData1();
          notesOn[pitch][channel] = event.getTick();
        } else if (command == ShortMessage.NOTE_OFF) {
          int pitch = ((ShortMessage) event.getMessage()).getData1();
          long duration = event.getTick() - notesOn[pitch][channel];
          int velocity = ((ShortMessage) event.getMessage()).getData2();
          notes[channel].add(new MidiNote(pitch, velocity, event.getTick(), duration));
        }
      }
    }
    return notes;
  }


  public ArrayList<MyTrack> loadMidiFile(File inputFile) {
    ArrayList<MyTrack> loadedTracks = new ArrayList();
    for (int i=0; i<16; i++) {
      loadedTracks.add(new MyTrack());
    }

    try {
      MidiFileFormat format = MidiSystem.getMidiFileFormat(inputFile);
      println("File type : " + format.getType());
      Sequence seq = MidiSystem.getSequence(inputFile);
      for (Track track : seq.getTracks()) {
        println("track");
        // Convert from midi file tracks to this sequencer track format
        ArrayList<MidiNote>[] arrays = parseEvents(track);
        for (int i=0; i<16; i++) {
          if (!arrays[i].isEmpty()) {
            Pattern newPattern = new Pattern();
            newPattern.addNotes(arrays[i]);
            newPattern.trimLength();
            println(newPattern.getLength());
            loadedTracks.get(i).addPattern(newPattern);
          }
        }
      }

      tracks.clear();
      tracks.addAll(loadedTracks);

      return loadedTracks;
    } 
    catch (InvalidMidiDataException e) {
      e.printStackTrace();
    } 
    catch (IOException e) {
      e.printStackTrace();
    }
    return loadedTracks;
  }
}
