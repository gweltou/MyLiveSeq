import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.PriorityQueue;
import java.util.Collections;
import javax.sound.midi.*;
import javax.sound.sampled.AudioSystem;
import javax.sound.sampled.AudioFormat;
import javax.sound.sampled.Clip;
import javax.sound.sampled.LineUnavailableException;


public ArrayList<MidiNote> algoMel1(ArrayList<MidiNote> notes, float prob) {
  // Raise or lower notes by 1 octave
  
  ArrayList<MidiNote> mutated = new ArrayList<MidiNote>();
  for (MidiNote n : notes) {
    if (Math.random() < prob) {
      int pitch = n.getPitch();
      if (Math.random() < 0.5f) {
        pitch = max(0, pitch-12);
      } else {
        pitch = min(127, pitch+12);
      }
      n = new MidiNote(pitch, n.getVelocity(), n.getStart(), n.getDuration());
    }
    mutated.add(n);
  }
  return mutated;
}


Clip beepHigh;
Clip beepLow;
public byte[] createSoundSample(float sampleRate, float hz, int cycles, float amp) {
  float framesPerCycle = sampleRate/hz;
  int nFrames = ceil(framesPerCycle * cycles);
  float angleStep = TWO_PI / framesPerCycle;
  byte[] data = new byte[2 * nFrames];
  float angle = 0;
  for (int i=0; i<nFrames; i++) {
    short val = (short) (amp * pow(2, 15) * sin(angle));
    angle += angleStep;
    data[2*i] = (byte) ((val >> 8) & 0xFF);
    data[2*i + 1] = (byte) (val & 0xFF);
  }
  return data;
}


/***************************************************
 *****************   MIDI NOTE   *******************
 ***************************************************/
public class MidiNote {
  private int pitch;
  private int velocity;
  private long start;
  private long duration;

  public MidiNote(int pitch, int velocity, long start, long duration) {
    this.pitch = pitch;
    this.velocity = velocity;
    this.start = start;
    this.duration = duration;
  }

  public int getPitch() { 
    return pitch;
  }
  public void setPitch(int p) { 
    pitch = p;
  }
  public int getVelocity() { 
    return velocity;
  }
  public void setVelocity(int v) { 
    velocity = v;
  }
  public long getStart() { 
    return start;
  }
  public void setStart(long s) { 
    start = s;
  }
  public long getEnd() { 
    return start+duration;
  }
  public long getDuration() { 
    return duration;
  }
  public void setDuration(long d) { 
    duration = d;
  }

  public ArrayList<MidiEvent> asEvents(int channel, long offset) {
    ArrayList<MidiEvent> events = new ArrayList(2);
    try {
      ShortMessage noteOn = new ShortMessage(ShortMessage.NOTE_ON, channel, getPitch(), getVelocity());
      ShortMessage noteOff = new ShortMessage(ShortMessage.NOTE_OFF, channel, getPitch(), 0);
      events.add(new MidiEvent(noteOn, offset));
      events.add(new MidiEvent(noteOff, offset+getDuration()));
    } 
    catch (InvalidMidiDataException e) {
      e.printStackTrace();
    }
    return events;
  }
}

public static class NoteComparator implements Comparator<MidiNote> {
  @Override
    public int compare(MidiNote o1, MidiNote o2) {
    return Long.compare(o1.getStart(), o2.getStart());
  }
}



/***************************************************
 ******************    PATTERN    ******************
 ***************************************************/
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
  protected final ArrayList<MidiEvent> midiEvents = new ArrayList();
  protected final ArrayList<MidiNote> midiNotes = new ArrayList();
  private long nTicks = 0;
  private Pattern childPattern = null;

  public Pattern() { 
    this(32*midiManager.getPPQ());
  }
  public Pattern(long ticks) {
    setLength(ticks);
  }
  public Pattern(Pattern other) {
    setLength(other.getLength());
    midiNotes.addAll(other.getNotes());
    midiEvents.addAll(other.getEvents());
  }
  
  public void algoMel1(float prob) {
    ArrayList<MidiNote> mutated = this.algoMel1(this.midiNotes, prob);
    childPattern = new Pattern();
    childPattern.addNotes(mutated);
  }
  
  public ArrayList<MidiNote> algoMel1(ArrayList<MidiNote> notes, float prob) {
    // Raise or lower notes by 1 octave
    
    ArrayList<MidiNote> mutated = new ArrayList<MidiNote>();
    for (MidiNote n : notes) {
      if (Math.random() < prob) {
        int pitch = n.getPitch();
        if (Math.random() < 0.5f) {
          pitch = max(0, pitch-12);
        } else {
          pitch = min(127, pitch+12);
        }
        n = new MidiNote(pitch, n.getVelocity(), n.getStart(), n.getDuration());
      }
      mutated.add(n);
    }
    return mutated;
  }

  public void setRndMel(float r) { 
    println("mutating pattern");
    algoMel1(r*0.2);
  }
  public void setRndRyt(float r) { 
    println("mutating pattern");
  }
  
  public void setLength(long ticks) { 
    this.nTicks = ticks;
    println("MM: pattern set length to "+ticks);
  }
  public long getLength() {
    return nTicks;
  }
  public void trimLength() {
    // Adjust pattern length to last note off
    nTicks = 0;
    for (MidiNote note : midiNotes) {
      if (note.getEnd() > nTicks)
        nTicks = note.getEnd();
    }
    println("MM: trimlength "+nTicks);
  }

  public void stretchTo(long ticks) {
    println("MM Pattern: stretchto "+ticks);
    float ratio = ticks / getLength();
    setLength(ticks);
    ArrayList<MidiNote> stretchedNotes = new ArrayList();
    ArrayList<MidiEvent> stretchedEvents = new ArrayList();
    for (MidiNote note : getNotes()) {
      long start = Math.round(note.getStart()*ratio);
      long duration = Math.round(note.getDuration()*ratio);
      MidiNote stretchedNote = new MidiNote(note.getPitch(), note.getVelocity(), start, duration);
      stretchedNotes.add(stretchedNote);
    }
    for (MidiEvent event : getEvents()) {
      long tick = Math.round(event.getTick()*ratio);
      MidiEvent stretchedEvent = new MidiEvent(event.getMessage(), tick);
      stretchedEvents.add(stretchedEvent);
    }
    midiEvents.clear();
    midiEvents.addAll(stretchedEvents);
    midiNotes.clear();
    midiNotes.addAll(stretchedNotes);
  }

  public ArrayList<MidiEvent> getEvents() { 
    return midiEvents;
  }
  public void addEvent(MidiEvent event) { 
    midiEvents.add(event);
    Collections.sort(midiEvents, midiManager.new EventComparator()); // UGLY
  }

  public void addNote(MidiNote note) { 
    midiNotes.add(note);
    sort();
  }
  public void addNotes(ArrayList<MidiNote> notes) {
    midiNotes.addAll(notes);
    sort();
  }
  public ArrayList<MidiNote> getNotes() {
    if (childPattern != null) {
      return childPattern.getNotes();
    }
    return midiNotes;
  }
  public void remove(MidiNote note) { 
    midiNotes.remove(note);
  }
  public void sort() {
    Collections.sort(midiNotes, new NoteComparator());
  }

  public ArrayList<MidiEvent> asEvents(int channel, long offset) {
    ArrayList<MidiEvent> events = new ArrayList();
    for (MidiNote note : getNotes()) {
      ShortMessage noteOn, noteOff;
      try {
        noteOn = new ShortMessage(ShortMessage.NOTE_ON, channel, note.getPitch(), note.getVelocity());
        noteOff = new ShortMessage(ShortMessage.NOTE_OFF, channel, note.getPitch(), 0);
        events.add(new MidiEvent(noteOn, offset+note.getStart()));
        events.add(new MidiEvent(noteOff, offset+note.getEnd()));
      }
      catch (InvalidMidiDataException e) {
        e.printStackTrace();
      }
    }
    return events;
  }

  public Pattern[] divide(long ticks) {
    println("MM: dividing pattern ("+getLength()+") at "+ticks);
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



/***************************************************
 ******************     TRACK    *******************
 ***************************************************/
public class MyTrack {
  /*
   *  Paramètres :
   *      Mute on/off
   *      Midi Channel
   *      Transpose Octave
   *      Transpose semi-tones
   */
  private int midiChannel;
  private final ArrayList<Pattern> patterns = new ArrayList();
  //private ArrayList<MidiEvent> events = new ArrayList();
  private int patternIdx;
  private int noteIdx;
  //private int eventIdx;
  private long tickcount;
  private boolean mute;
  private int octave;
  private int semitone;
  private float rndMel = 0.0;
  private float rndRyt = 0.0;

  private int playmode;
  static public final int EOT = 0;            // Stop at end of track
  static public final int LOOP_TRACK = 1;     // Loop whole track
  static public final int LOOP_PATTERN = 2;   // Loop current pattern

  public MyTrack() {
    midiChannel = 0;
    patternIdx = 0;
    noteIdx = 0;
    //eventIdx = 0;
    mute = false;
    playmode = EOT;
    tickcount = 0;
  }

  public void addPattern(Pattern pattern) {
    patterns.add(pattern);
    println("MM: Pattern added to track " + this);
    println("    Pattern length "+pattern.getLength());
  }
  public void addPattern(int idx, Pattern pattern) { 
    patterns.add(idx, pattern);
    println("MM: Pattern added to track " + this);
  }
  public void removePattern(Pattern pat) { 
    patterns.remove(pat);
    println("MM: Pattern removed from track " + this);
  }
  public ArrayList<Pattern> getPatterns() {
    return patterns;
  }

  public void setChannel(int chan) {
    // Chan: midi channel from 0 to 15
    midiChannel = chan;
    println("MM: channel set to " + midiChannel);
  }
  public int getChannel() { 
    return midiChannel;
  }
  public void setMode(int mode) { 
    playmode = mode;
  }

  public void mute() { 
    println("MM: track muted");
    mute=true;
  }
  public void unMute() {
    println("MM: track unmuted");
    mute=false;
  }
  public boolean isMuted() {
    return mute;
  }

  public void setOctave(int o) { 
    octave = o;
  }
  public int getOctave() { 
    return octave;
  }
  public int getSemitone() { 
    return semitone;
  }
  public void setSemitone(int s) { 
    semitone = s;
  }
  public float getRndMel() { 
    return rndMel;
  }
  public void setRndMel(float r) { 
    rndMel = r; 
    patterns.get(patternIdx).setRndMel(r);
  }
  public float getRndRyt() { 
    return rndRyt;
  }
  public void setRndRyt(float r) { 
    rndRyt = r;
    patterns.get(patternIdx).setRndMel(r);
  }

  public long getTick() {
    long total = tickcount;
    for (int i=0; i<patternIdx; i++) {
      total += patterns.get(i).getLength();
    }
    return total;
  }
  public void rewind() {
    patternIdx = 0;
    tickcount = 0;
    noteIdx = 0;
  }

  public ArrayList<MidiEvent> tick(long localTick) {
    // Return the events to be played when timing is right
    // null otherwise
    if (patternIdx < patterns.size()) {
      ArrayList<MidiEvent> toPlay = new ArrayList(8);

      if (tickcount == 0) {
        // Apply randomness to pattern
        if (getRndMel() > 0) {
          patterns.get(patternIdx).setRndMel(getRndMel());
        } 
      }

      if (!mute) {
        ArrayList<MidiNote> notes = patterns.get(patternIdx).getNotes();
        MidiNote note;
        while (noteIdx<notes.size() && notes.get(noteIdx).getStart() <= tickcount) {
          note = notes.get(noteIdx);
          if (octave != 0 || semitone != 0) {
            // Transpose notes by octaves and semitones
            int pitch = Math.min(127, Math.max(0, note.getPitch()+12*octave+semitone));
            note = new MidiNote(pitch, note.getVelocity(), note.getStart(), note.getDuration());
          }
          ArrayList<MidiEvent> events = note.asEvents(getChannel(), localTick);
          toPlay.addAll(events);
          noteIdx++;
        }
      }

      tickcount++;
      if (tickcount >= patterns.get(patternIdx).getLength()) {
        tickcount = 0;
        noteIdx = 0;
        if (playmode != LOOP_PATTERN) {
          patternIdx++;
        }
      }
      if (playmode == LOOP_TRACK && patternIdx>=patterns.size()) {
        // Cumulates with above initialization
        patternIdx = 0;
      }

      return toPlay;
    }
    return null;
  }
}



/***************************************************
 ****************** MIDI MANAGER *******************
 ***************************************************/
public class MidiManager extends Thread {
  private boolean stopThread;    // MidiManager stops when stopThread is set to false
  private final ArrayList<MyTrack> tracks = new ArrayList();
  private final PriorityQueue<MidiEvent> eventQueue;
  private final ArrayList<MidiDevice> transmitters = new ArrayList();
  private final ArrayList<MidiDevice> receivers = new ArrayList();
  private MidiDevice inputDevice, outputDevice;
  private MyMidiReceiver midiIn;
  private Receiver midiOut;

  private final boolean[] onNotes = new boolean[16*128];  // 16 midi channels, 128 pitches per channel
  public boolean running;
  public boolean recording;
  private Pattern activePattern;
  private boolean patternPlaying = false;
  private long patternTick;
  private long songTick;
  private MyTrack soloTrack;
  private long lastTickTime;
  private long localTick;
  private long lastLocalTickTime;
  private long localTickDuration;
  private long externalTickDuration;
  private final int tickResolution = 96; // Pulse Per Quarter note
  private boolean clockSlave;
  private long now;
  private long prev;
  private int beat;

  public MidiManager() {
    Arrays.fill(onNotes, false);
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
    beat = 0;
    now = System.currentTimeMillis();
    //playPause();
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
      println(message, localTick);
      if (message.getStatus() == ShortMessage.TIMING_CLOCK) {
        // Ignore clock timing messages for now
      } else if (readBufferIndex < readBuffer.length) {
        readBuffer[readBufferIndex++] = new MidiEvent(message, localTick);
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
    if (inputDevice != null)
      inputDevice.close();
    if (input_device == -1)
      return;
    if (transmitters.isEmpty())
      getTransmitters();

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
    if (outputDevice != null) {
      stopAndRewind();
      outputDevice.close();
      println("MM: closing output device");
    }
    if (output_device == -1)
      return;
    if (receivers.isEmpty())
      getReceivers();

    try {
      outputDevice = receivers.get(output_device);
      outputDevice.open();
      midiOut = outputDevice.getReceiver();
      String desc = outputDevice.getDeviceInfo().getDescription();
      println("Périphérique de sortie Midi ouvert (" + desc + ")");
      testNote();
    } 
    catch (MidiUnavailableException e) {
      println("Impossible d'ouvrir le périphérique de sortie Midi");
    }
  }

  public void testNote() {
    try {
      midiOut.send(new ShortMessage(ShortMessage.NOTE_ON, 60, 80), -1);
      midiOut.send(new ShortMessage(ShortMessage.NOTE_ON, 64, 80), -1);
      midiOut.send(new ShortMessage(ShortMessage.NOTE_ON, 67, 80), -1);
      try {
        Thread.sleep(200);
      } 
      catch (InterruptedException e) {
        e.printStackTrace();
      }
      midiOut.send(new ShortMessage(ShortMessage.NOTE_OFF, 60, 0), -1);
      midiOut.send(new ShortMessage(ShortMessage.NOTE_OFF, 64, 80), -1);
      midiOut.send(new ShortMessage(ShortMessage.NOTE_OFF, 67, 80), -1);
    } 
    catch (InvalidMidiDataException e) {
      e.printStackTrace();
    }
  }

  public boolean playPause() {
    if (running) {
      println("MM: Playing paused");
      allNotesOff();
      running = false;
    } else {
      println("MM: Playing started");
      // Why are we reseting tickTimes ? (we lose a tick)
      now = System.currentTimeMillis();
      lastTickTime = now;
      lastLocalTickTime = now;
      running = true;
    }
    return running;
  }

  public void songMode() {
    patternPlaying = false;
    stopAndRewind();
  }

  public void stopAndRewind() {
    println("MM: Stop and Rewind");
    if (patternPlaying) {
      patternTick = 0;
    } else {
      songTick = 0;
      for (MyTrack track : tracks) {
        track.rewind();
      }
    }

    allNotesOff();
    running = false;
  }

  public void allNotesOff() {
    // Turn off all playing notes
    for (int channel=0; channel<16; channel++) {
      for (int pitch=0; pitch<128; pitch++) {
        int idx = 128*channel + pitch;
        if (onNotes[idx]) {
          try {
            midiOut.send(new ShortMessage(ShortMessage.NOTE_OFF, channel, pitch, 0), -1);
          } 
          catch (InvalidMidiDataException e) {
            e.printStackTrace();
          }
          onNotes[idx] = false;
        }
      }
    }
    //eventQueue.clear();
  }

  public void addTrack(MyTrack track) { 
    tracks.add(track);
  }

  public void solo(MyTrack t) {
    soloTrack = t;
    if (t != null && t.isMuted())
      t.unMute();
  }
  public MyTrack getSolo() { 
    return soloTrack;
  }

  public void playPattern(Pattern pattern) {
    eventQueue.clear();
    activePattern = pattern;
    patternTick = 0;
    patternPlaying = true;
    playPause();
    println("MM: Pattern loop started");
  }

  public boolean isRunning() { 
    return running;
  }

  public void startRecording(Pattern pattern) {
    if (isRecording()) {
    } else {
      println("MM: Recording started");
      activePattern = pattern;
      recording = true;
    }
  }

  public boolean isRecording() { 
    return recording;
  }

  public void setBpm(float bpm) {
    externalTickDuration = Math.round(60000/(24 * bpm));   // 24 ticks per quarter-note
    localTickDuration = Math.round(60000/(tickResolution * bpm));
  }

  public long getTick() { 
    return localTick;
  }
  public long getSongTick() { 
    return songTick;
  }
  public long getPatternTick() { 
    return patternTick;
  }

  public long getPPQ() {
    return tickResolution;
  }

  public void update() {
    // Read Midi Events from midiIn
    MidiEvent[] newEvents = (midiIn == null) ? null : midiIn.getEvents();

    // Send midiIn events to midiOut
    if (midiOut != null && newEvents != null) {
      for (MidiEvent event : newEvents) {
        midiOut.send(event.getMessage(), -1);
      }
    }

    prev = now;
    now = System.currentTimeMillis();
    // Check if update rate is fast enough
    if (now-prev > localTickDuration>>2) {
      println("lagging");
    }
    
    if (isRunning()) {
      // Manage clock
      if (!clockSlave) {
        // Update local ticks (may have a greater resolution that default Midi ticks)
        if (now - lastLocalTickTime >= localTickDuration) {
          tick();
          lastLocalTickTime += localTickDuration;
        }
        if ((midiOut != null) && (now - lastTickTime > externalTickDuration)) {
          // Send clock tick to external hardware/software
          try {
            ShortMessage tickMessage = new ShortMessage(ShortMessage.TIMING_CLOCK);
            midiOut.send(tickMessage, -1);
          } 
          catch (InvalidMidiDataException ignored) {
          }
          lastTickTime += externalTickDuration;
        }
      }

      // Send queued Midi events to midiOut
      while (!eventQueue.isEmpty() && eventQueue.peek().getTick() <= localTick) {
        ShortMessage nextMessage = (ShortMessage) eventQueue.poll().getMessage();
        int channel = nextMessage.getChannel();
        // Keep track of active notes (used to cleanly turn notes off when needed)
        if ((nextMessage.getStatus()&0xF0) == ShortMessage.NOTE_ON) {
          int pitch = nextMessage.getData1();
          onNotes[128*channel + pitch] = true;
        } else if ((nextMessage.getStatus()&0xF0) == ShortMessage.NOTE_OFF) {
          int pitch = nextMessage.getData1();
          onNotes[128*channel + pitch] = false;
        }
        if (midiOut != null)
          midiOut.send(nextMessage, -1);
      }
    }
  }

  private void tick() {
    if (patternPlaying) {
      if (patternTick == 0) {
        eventQueue.addAll(activePattern.asEvents(1, localTick));
        println("MM: pattern looped");
      }
      patternTick += 1;
      if (patternTick >= activePattern.getLength()) {
        patternTick = 0;
      }

      //  Record events to current pattern
      if (isRecording()) {
        if (patternTick % getPPQ() == 0) {
          if (beat == 0) {
            //beepHigh.stop();
            beepHigh.setFramePosition(0);
            beepHigh.start();
          } else {
            //beepLow.stop();
            beepLow.setFramePosition(0);
            beepLow.start();
          }
          beat = (beat+1) % 4;
        }
      }
    } else {
      // Song mode
      for (MyTrack t : tracks) {
        ArrayList<MidiEvent> trackEvents = t.tick(localTick);
        if (trackEvents == null)
          continue;
        if (soloTrack == null) {
          eventQueue.addAll(trackEvents);
        } else {
          if (soloTrack == t) {
            eventQueue.addAll(trackEvents);
          }
        }
      }
      songTick += 1;
    }
    localTick += 1;
  }

  public void run () {
    println("Midi manager started...");

    // Create click track sound samples
    AudioFormat format = new AudioFormat(44100f, 16, 1, true, true);
    byte[] beepLowBuffer = createSoundSample(44100, 880, 8, 0.3);
    byte[] beepHighBuffer = createSoundSample(44100, 1760, 16, 0.5);
    try {
      beepLow = AudioSystem.getClip();
      beepLow.open(format, beepLowBuffer, 0, beepLowBuffer.length);
      beepHigh = AudioSystem.getClip();
      beepHigh.open(format, beepHighBuffer, 0, beepHighBuffer.length);
    } 
    catch (LineUnavailableException e) {
      e.printStackTrace();
    }

    stopThread = false;
    while (!stopThread) {
      update();
      /*
      try {
        Thread.sleep(1L);
      } 
      catch (InterruptedException ignored) {
      }
      */
    }

    // Close Midi ports
    if (outputDevice != null)
      outputDevice.close();
    if (inputDevice != null)
      inputDevice.close();
  }

  public void shutdown() {
    stopThread = true;
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


  public MyTrack parseEvents(Track track, int ppq) {
    int channel = -1;
    float timeScale = (float) tickResolution / ppq;

    ArrayList<MidiNote> notes = new ArrayList();
    long[] notesOnTick = new long[128*16];
    Arrays.fill(notesOnTick, -1);
    int[] notesOnVel = new int[128*16];
    Arrays.fill(notesOnVel, 0);

    for (int i=0; i<track.size(); i++) {
      MidiEvent event = track.get(i);
      /*
      if (event.getMessage().getStatus() == 0xFF) {
       // Meta message
       MetaMessage meta = (MetaMessage) event.getMessage();
       if (meta.getType() == 0x51) {
       println("tempooooooo");
       println(meta.getData());
       }
       }*/

      int status = event.getMessage().getStatus() & 0xF0;
      if (status == ShortMessage.NOTE_ON || status == ShortMessage.NOTE_OFF) {
        ShortMessage message = (ShortMessage) event.getMessage();
        int command = message.getCommand();
        if (channel == -1) {
          channel = message.getChannel();
          println("channel " + channel);
        }
        if (command == ShortMessage.NOTE_ON) {
          int pitch = message.getData1();
          notesOnTick[channel*128+pitch] = event.getTick();
          notesOnVel[channel*128+pitch] = message.getData2();
        } else if (command == ShortMessage.NOTE_OFF) {
          int pitch = message.getData1();
          long start = Math.round(notesOnTick[channel*128+pitch]*timeScale);
          long duration = Math.round((event.getTick()-notesOnTick[channel*128+pitch])*timeScale);
          int velocity = notesOnVel[channel*128+pitch];
          notes.add(new MidiNote(pitch, velocity, start, duration));
        }
      }
    }

    if (notes.size() > 0) {
      MyTrack newTrack = new MyTrack();
      Pattern newPattern = new Pattern();
      newPattern.addNotes(notes);
      newPattern.trimLength();
      newTrack.addPattern(newPattern);
      newTrack.setChannel(channel);
      return newTrack;
    }
    return null;
  }


  public ArrayList<MyTrack> loadMidiFile(File inputFile) {
    ArrayList<MyTrack> loadedTracks = new ArrayList();

    try {
      MidiFileFormat format = MidiSystem.getMidiFileFormat(inputFile);
      int ppq = format.getResolution();
      Sequence seq = MidiSystem.getSequence(inputFile);
      println("File type : " + format.getType());
      println("      ppq : " + format.getResolution());
      println("      div : " + format.getDivisionType());
      println("      " + seq.getTracks().length + " tracks");

      //int i=0;
      for (Track track : seq.getTracks()) {
        // Convert from midi file tracks to this sequencer track format
        MyTrack newTrack = parseEvents(track, ppq);
        if (newTrack != null)
          loadedTracks.add(newTrack);
      }

      solo(null);
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
