//Defines the rhythms available to be synthesized

import ddf.minim.*;
import ddf.minim.ugens.*;

class Rhythm 
{ 
  private float[] times;
  private float duration;
  
  public float getDuration() { return duration; }
  public int getNumNotes() { return times.length; }
  
  public Rhythm(float[] times)
  {
   this.times = new float[times.length];
   duration = 0;
   for(int i = 0; i < times.length; i++)
   {
     this.times[i] = times[i];
     duration += this.times[i];
   }
  }
  
  public void play(AudioOutput out, ArrayList<String> notes)
  {
    if (notes.size() != times.length)
    {
      println("Error: Attempting to match up note sequence with different size rhythm!");
      return;
    }
    
    //out.pauseNotes();
    /*for (int i = 0; i < (int)(duration * 2); i++)
    {
      out.playNote(i, 1, "C2");
    }*/
    float lastTime = 0.0;
    for(int i = 0; i < times.length; i++)
    {
        out.playNote(lastTime, times[i], notes.get(i));
        out.playNote(lastTime, times[i], notes.get(i)); //Double the volume by playing it twice, since Minim doesn't have velocity control
        //out.playNote(lastTime + duration, times[i], notes[i]); //Comment out for actual production
        lastTime += times[i];
    }
    //out.resumeNotes();
  }
}