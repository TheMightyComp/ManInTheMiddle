class Dot
{ 
  private int x, y, r, speedX, speedY;
  private float life, originalLife;
  private color c;
  public int getX() { return x; }
  public int getY() { return y; }
  public int getR() { return r; }
  public color getC() { return c; }
  public float getLife() { return life; }
  public void setX(int x) { this.x = x; }
  public void setY(int y) { this.y = y; }
  public void setR(int r) { this.r = r; }
  public void setC(int r, int g, int b, int a) { this.c = color(a, r, g, b); }
  
  public Dot(int x, int y, int r, int c, float life)
  {
    this.x = x;
    this.y = y;
    this.r = r;
    if(this.r > 3 * height / 4)
      this.r = 3 * height / 4;
    this.c = c;
    this.life = life;
    this.originalLife = life;
    speedX = (int)(noise(x) * Constants.DOT_SPEED);
    speedY = (int)(noise(y) * Constants.DOT_SPEED * 3);
  }
  
  public void update(int deltaT)
  {
    life -= (float)(deltaT) / (1000f);
    y += (int)(((float)(deltaT) / (100f)) * (float)speedY);
    
  }
  
  public void draw()
  {
    fill(c);
    ellipse(x, y, (float)r * (life / originalLife), (float)r * (life / originalLife));
  }
}