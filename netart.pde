import org.rsg.carnivore.*;
import org.rsg.lib.Log;
import ddf.minim.*;
import ddf.minim.ugens.*;

//TODO: Add audio panning?
//TODO: Add curve for volume

//Set up the packet sniffing objects
CarnivoreP5 c;
int packetCount = 0;
String mostRecentPayload = "";

//Set up the audio stuff
Minim minim;
AudioOutput out;

//Algorithmic composition elements
ArrayList<Rhythm> rhythms;
ArrayList<ArrayList<String>> harmonies; //This is stupid, but bear with me.
int curHarmony = 0;
int curMeasure = 0;

boolean playingBassline = false;
int curMillis = 0;
int lastMillis = 0;
int lastStartTime;
float lastDuration = 0;
String curKey = "G2";
int availableModulations[] = {1, 2, 3, 4, -1, -2, -3, -4}; //Available intervals by which to modulate
int netModulation = 0;

//Circles
ArrayList<Dot> dots;
int i = 0;

void setup()
{  
  background(255);
  fullScreen();
  background(255);
  frameRate(60);
  
  //Minim initial setup
  minim = new Minim(this);
  out = minim.getLineOut();
  out.setTempo(100);
  out.setGain(10);
  
  //Carnivore setup
  c = new CarnivoreP5(this); 
  c.setShouldSkipUDP(false); //We want all the packets
  //Log.setDebug(false); // Uncomment for verbose mode
  //c.setVolumeLimit(4); //limit the output volume (optional)
  
  //Sets up the available rhythms
  rhythms = new ArrayList<Rhythm>();
  //Rhythms in 2
  rhythms.add(new Rhythm(new float[]{.5, .5, .5, .5})); //8 8 8 8
  rhythms.add(new Rhythm(new float[]{.25, .5, .25, .5, .25, .25})); //16 8 16 8 16 16
  rhythms.add(new Rhythm(new float[]{.25, .5, .5, .5, .25})); //16 8 8 8 16
  rhythms.add(new Rhythm(new float[]{1, .5, .5})); //4 8 8
  rhythms.add(new Rhythm(new float[]{.25, .25, .5, .5, .5})); //16 16 8 8 8
  //Rhythms in 3
  rhythms.add(new Rhythm(new float[]{.5, .5, 1, .5, .5})); //8 8 1 8 8
  rhythms.add(new Rhythm(new float[]{1, .5, .5, .25, .25, .5})); //1 8 8 16 16 8
  rhythms.add(new Rhythm(new float[]{.25, .25, .5, .25, .25, .5, .5, .25, .25})); //16 16 8 16 16 8 8 16 16  
  //Rhythms in weird-ass meters
  rhythms.add(new Rhythm(new float[]{.25, .25, .5, .5}));
  rhythms.add(new Rhythm(new float[]{.33, .33, .33, .5, .5, .5}));
  rhythms.add(new Rhythm(new float[]{.25, .25, .25, .25, .125, .125, .25}));
  
  //Sets up harmonies
  //Harmonies are stored in an arraylist of strings. Multiple notes played at once are separated by spaces within string
  harmonies = new ArrayList<ArrayList<String>>();
  
  //Harmony 0
  harmonies.add(new ArrayList<String>());
  harmonies.get(0).add("C4 E3");
  harmonies.get(0).add("C4 G4");
  harmonies.get(0).add("D4 G4");
  harmonies.get(0).add("D4 A3 A4");
  
  //Harmony 1
  harmonies.add(new ArrayList<String>());
  harmonies.get(1).add("A4 C4");
  harmonies.get(1).add("C4 G3");
  harmonies.get(1).add("C4 G3 A3");
  harmonies.get(1).add("C4 A3 D3");
  
  //Harmony 2
  harmonies.add(new ArrayList<String>());
  harmonies.get(2).add("C4 E3");
  harmonies.get(2).add("C4 Ab3 E3");
  harmonies.get(2).add("C4 Ab3 Eb3");
  
  //Harmony 3
  harmonies.add(new ArrayList<String>());
  harmonies.get(3).add("C4 A3");
  harmonies.get(3).add("D4 B3");
  harmonies.get(3).add("C4 E4");
  harmonies.get(3).add("D4 B3");
  
  //Harmony 4
  harmonies.add(new ArrayList<String>());
  harmonies.get(4).add("E3 G3 C4");
  harmonies.get(4).add("E3 Eb3 G3 Ab3 C4");
  harmonies.get(4).add("E3 G3 C4");
  harmonies.get(4).add("E3 Eb3 G3 Ab3 C4");
  
  //Harmony 5
  harmonies.add(new ArrayList<String>());
  harmonies.get(5).add("F#3 G3 C4");
  harmonies.get(5).add("D3 G3 C4");
  harmonies.get(5).add("Eb3 G3 C4");
    
  //Set up dots
  dots = new ArrayList<Dot>();
}

// Called each time a new packet arrives
void packetEvent(CarnivorePacket p)
{
  /*println(++packetCount);
  println("(" + p.strTransportProtocol + " packet) " + p.senderSocket() + " > " + p.receiverSocket()); //<>//
  println("Payload: " + p.ascii());
  println("---------------------------\n"); */

  mostRecentPayload = p.ascii();
  //Position is based of off the lagetDuration()st two bytes of the sender's IP address
  //Lifetime is based of off the length of the packet's body
  //Color is based of off the reciever's IP address
  dots.add(new Dot(width / 20 * (p.senderAddress.octet3() - 160) + (int)(Constants.NOISE_WEIGHT * (noise(p.senderAddress.octet3()))), height / 265 * p.senderAddress.octet4() + (int)(Constants.NOISE_WEIGHT * (noise(p.senderAddress.octet4()))),
    (int)(Constants.DOT_SIZE * p.ascii().length()), 
    //color((int)(noise(millis()) * 255f), (int)(noise(millis() * 2) * 255f), (int)(noise(p.ascii().length()) * 255f), 128),
    color(p.receiverPort % 256, p.senderPort % 256, (int)(noise(p.receiverPort) * 256f), 128),
    float(p.ascii().length()) * Constants.DOT_LIFE));
  
}

void draw()
{
  lastMillis = curMillis;
  curMillis = millis();
  int deltaT = curMillis - lastMillis;
 
  //auditory
  
  if ((out.getTempo() * ( (float)(curMillis - lastStartTime) ) / (60.0 * 1000.0)) > lastDuration)
    playingBassline = false;
    
  if(!playingBassline)
    playBaseline();
    
  //visual
  
  //Try-catch needed for ConcurrentModificationExceptions - Carnivore runs in a separate thread.
  //It doesn't matter if we miss a frame or two, because we aren't clearing the background buffer.
  //It's artsy fartsy
  try{
    //background(0);
    for (Dot d : dots){ 
      d.update(deltaT);
      if(d.getLife() <= 0)
      {
        dots.remove(d);
        continue;
      }
      d.draw(); 
    }
  }
  catch(Exception e){
    //Something should probably go here, but I'm too lazy to write it.
    //println("Encountenred exception " + e);
  }
}

//Actually plays everything, not just the baseline
void playBaseline()
{
  int rhythmToPlay = Math.abs(mostRecentPayload.hashCode()) % (rhythms.size());
  //println(rhythmToPlay);
  Rhythm r = rhythms.get(rhythmToPlay);
  ArrayList<String> notes = new ArrayList<String>();
  
  //Play the baseline
  for(int i = 0; i < r.getNumNotes(); i++)
    notes.add(curKey);
    
  //Play the harmony
  //out.pauseNotes();
  String[] curNotes = harmonies.get(curHarmony).get(curMeasure).split(" ");
  for(int i = 0; i < curNotes.length; i++)
    out.playNote(0, r.getDuration(), modulate(curNotes[i], netModulation));
  
  for(int i = 0; i < (int)(r.getDuration() * 4f); i++)
  {
    out.playNote( ((float)(i)) * .25f, 1, modulate(curNotes[(int)(abs((float)mostRecentPayload.hashCode() * noise(i))) % curNotes.length], 12 + netModulation));
    //Added
  }
  //out.resumeNotes();
  
  r.play(out, notes);
   
  if(++curMeasure >= harmonies.get(curHarmony).size()) //We're done with the current harmony
  {
    curHarmony = Math.abs(mostRecentPayload.hashCode()) % harmonies.size();
    curMeasure = 0;
    
    if (noise(mostRecentPayload.hashCode()) < Constants.MODULATION_FREQUENCY) //TIME TO MODULATE! HOORAY!
    {
      int mod = availableModulations[abs(mostRecentPayload.hashCode()) % availableModulations.length];
      //Don't modulate above an octave
      if (netModulation > Constants.MAX_MODULATION)
        netModulation -= abs(mod);
      else if (netModulation < -1 * Constants.MAX_MODULATION)
        netModulation += abs(mod);
      else
        netModulation += mod;
        
      curKey = modulate(Constants.STARTING_KEY, netModulation);
      println("HEY, I'M MODULATING HERE (" + netModulation + ")");
    }   
  }
   
  lastStartTime = millis();
  lastDuration = r.getDuration();
  playingBassline = true; 
}

//Modulates a given pitch up or down by 'interval' half steps
public String modulate(String in, int interval)
{
  if(interval > 0) //Modulating up
  {
    for(int i = 0; i < interval; i++)
    {
      if(in.length() > 2) //There's a sharp or a flat somewhere
      {
        if(in.charAt(1) == 'b') //Flats are easy
          in = in.substring(0, 1) + in.substring(2,3); //Remove the flat
        else if (in.charAt(0) == 'B') //B# -> C# and has to change octave numberings
          in = "C#" + (new Integer(Integer.parseInt(in.substring(2,3)) + 1)).toString();
        else if (in.charAt(0) == 'E') //E# -> F#
          in = "F#" + in.substring(2,3);
        else //A non-tricky sharp
          in = Character.toString(getNextLetter(in.charAt(0))) + in.substring(2,3);
      }
      else //There's no sharp or flat
      {
        if(in.charAt(0) == 'B') //Increment and change octaves
          in = "C" + (new Integer(Integer.parseInt(in.substring(1,2)) + 1)).toString();
        else if (in.charAt(0) == 'E')
          in = "F" + in.substring(1,2);
        else
          in = in.substring(0, 1) + "#" + in.substring(1, 2);
      }
    }
  }
  
  else if(interval < 0) //Modulating down
  {
    for(int i = 0; i < abs(interval); i++)
    {
      if(in.length() > 2) //There's a sharp or a flat somewhere
      {
        if(in.charAt(1) == '#') //Sharps are easy
          in = in.substring(0, 1) + in.substring(2,3); //Remove the sharp
        else if (in.charAt(0) == 'C') //Cb -> Bb and has to change octave numberings
          in = "Bb" + (new Integer(Integer.parseInt(in.substring(2,3)) - 1)).toString();
        else if (in.charAt(0) == 'F') //Fb -> Eb
          in = "Eb" + in.substring(2,3);
        else //A non-tricky flat
          in = Character.toString(getPreviousLetter(in.charAt(0))) + in.substring(2,3);
      }
      else //There's no sharp or flat
      {
        if(in.charAt(0) == 'C') //Decrement and change octaves
          in = "B" + (new Integer(Integer.parseInt(in.substring(1,2)) - 1)).toString();
        else if (in.charAt(0) == 'F')
          in = "E" + in.substring(1,2);
        else
          in = in.substring(0, 1) + "b" + in.substring(1, 2);
      }
    }
  }
  return in;
}

//Helper functions for modulation
public char getNextLetter(char in)
{
  return ++in <= 71 ? in : 'A';
}

public char getPreviousLetter(char in)
{
  return --in >= 65 ? in : 'G';
}

//Test function. It's pretty much useless
void makeNoise()
{
  out.playNote("A4");
}