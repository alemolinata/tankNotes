// The Nature of Code
// Daniel Shiffman
// http://natureofcode.com

class Particle {
  PVector loc;
  PVector vel;
  PVector acc;
  float lifespan;
  PImage img;

  Particle(PVector l,PImage img_, float lifespan_) {
    acc = new PVector(0,0);
    float vx = randomGaussian()*0.5;
    float vy = randomGaussian()*0.5 - 1.0;
    vel = new PVector(vx,vy);
    loc = l.get();
    lifespan = lifespan_;
    img = img_;
  }

  void run() {
    update();
    render();
  }
  
  // Method to apply a force vector to the Particle object
  // Note we are ignoring "mass" here
  void applyForce(PVector f) {
    acc.add(f);
  }  

  // Method to update location
  void update() {
    vel.add(acc);
    loc.add(vel);
    lifespan -= 1.5;
    acc.mult(0); // clear Acceleration
  }

  // Method to display
  void render() {
    pushStyle();
//    imageMode(CENTER);
//    tint(255,lifespan);
//    image(img,loc.x,loc.y, 64, 64);
    
    //ellipses instead of tint; 
    fill(255,lifespan);
    noStroke();
    rectMode(CENTER);
    rect(loc.x,loc.y, 12, 12);
    
    
    popStyle();
    // Drawing a circle instead
    // fill(255,lifespan);
    // noStroke();
    // ellipse(loc.x,loc.y,img.width,img.height);
  }

  // Is the particle still useful?
  boolean isDead() {
    if (lifespan <= 0.0) {
      return true;
    } else {
      return false;
    }
  }
}

