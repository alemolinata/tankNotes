class Explosion {
  PVector initPos = new PVector(0, 0);
  float explosionForce;
  public int noteLength;

  public int explosionPitch;

  public int timer = 0;

  public Explosion( PVector initialPosition, PVector velocity1, PVector velocity2 ) {
    super();
    initPos.set(initialPosition.x, initialPosition.y);
    explosionForce = velocity1.mag() + velocity2.mag();
    noteLength = int(map(explosionForce, 0, 100, 4, 15));
    //println(noteLength);
    explosionPitch = (int)map(initPos.y, 0, TankNotesProcessing.canvasHeight, 70, 38);
  }

  public void draw() {
    noStroke();
    fill(TankNotesProcessing.generateColor(initPos.y, height)-timer*0x0F000000);
    ellipse(initPos.x, initPos.y, timer*timer, timer*timer);
    timer++;
  }
}

