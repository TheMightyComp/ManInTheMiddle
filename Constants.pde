//Essentially just holds important parameters that control
//Large-scale aspects of the piece

public static class Constants
{
  public final static float DOT_LIFE = .01f; //The larger this variable, the longer dots last
  public final static int DOT_SIZE = 1; //How large the dots should be
  public final static int NOISE_WEIGHT = 5; //How much noise should be added to the XY coordinates of the dots
  public final static float DOT_SPEED = 0; //How fast the dots move
  public final static float MODULATION_FREQUENCY = .5f; //Probability that we will modulate on a given harmony change
  public final static String STARTING_KEY = "G3"; //Original key for baseline
  public final static int MAX_MODULATION = 9; //Don't modulate more than an octave
  
  public final static float dotAnimationFunction(float x)
  {
    return (1f / ( (.2f * x - 1f) * (x - 1f) + 1f));
  }
}