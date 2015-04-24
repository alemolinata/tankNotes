ParticleSystem ps;

PImage bgImg;

int damageTank1 = 0;
int damageTank2 = 0;

//OSC 
import oscP5.*;
import netP5.*;
OscP5 oscP5;
NetAddress myRemoteLocation;

int velValue;
int pitchValue;
int glitchSound;
int glitchBackground;

//MIDI
import themidibus.*; //Import the library
MidiBus myBus; // The MidiBus

int noteLength = 10; 

int channel = 1 ;
int noteVelocity = 127;

long explosionTimer;

boolean clicking = false;

ArrayList<Explosion> explosions = new ArrayList<Explosion>();
ArrayList<CannonBall> cannonballs = new ArrayList<CannonBall>();
ArrayList<Star> stars = new ArrayList<Star>();

float ox1; // X coordinate of center of cannon 1
float oy1; // Y coordinate of center of cannon 1
float ox2; // X coordinate of center of cannon 2
float oy2; // Y coordinate of center of cannon 2
float cannonLength = 50;

float angleCannon1;
float angleCannon2;

float speedCannon1;
float speedCannon2;

long physicsCounter;

static int canvasWidth = 1400;
static int canvasHeight = 800;

static final PVector gravity = new PVector(0, 1);

void setup() {
  size(canvasWidth, canvasHeight, OPENGL);
  smooth();
  frameRate(30);

  //Smoke
  PImage img = loadImage("texture.png");
  ps = new ParticleSystem(0, new PVector(50, height-50), img);


  bgImg = loadImage("Background_greyscale_lofi.jpg");


  //OSC: start oscP5, listening for incoming messages at port 12000 
  oscP5 = new OscP5(this, 12000);
  myRemoteLocation = new NetAddress("127.0.0.1", 9000);

  //MIDI
  //MidiBus.list(); // List all available Midi devices on STDOUT. This will show each device's index and name.
  myBus = new MidiBus(this, 0, 1); // Create a new MidiBus using the device index to select the Midi input and output devices respectively.

  physicsCounter = millis();

  ox1 = 50;
  oy1 = height - 50;
  ox2 = width - 50;
  oy2 = oy1;
}

void draw() {

  image(bgImg, 0, 0);
  
  if (glitchBackground > 0){
   filter(INVERT); 
  }
  

  if (frameCount % 2 == 0) {
    int noteLength = 10;
  } else {
    int noteLength = 2;
  }


  explosionTimer++;
  readValues();

  float posx1 = ox1 + cos(angleCannon1) * cannonLength;
  float posy1 = oy1 + sin(angleCannon1) * cannonLength;

  float posx2 = ox2 + cos(angleCannon2) * cannonLength;
  float posy2 = oy2 + sin(angleCannon2) * cannonLength;

  float vx1 = speedCannon1 * cos(angleCannon1);
  float vy1 = speedCannon1 * sin(angleCannon1);

  float vx2 = speedCannon2 * cos(angleCannon2);
  float vy2 = speedCannon2 * sin(angleCannon2);

  if (mousePressed) {
    if (clicking == false) {
      PVector mPosition = new PVector(0, 0);
      PVector mVelocity = new PVector(0, 0);
      if (mouseX < width/2) {
        mPosition.set(posx1, posy1);
        mVelocity.set(vx1, vy1);
      } else {
        mPosition.set(posx2, posy2);
        mVelocity.set(vx2, vy2);
      }
      CannonBall mCannonBall = new CannonBall(mPosition, mVelocity);
      cannonballs.add(mCannonBall);
    }
    clicking = true;
  } else {
    clicking = false;
  }


  /* remove particles right before they hit the edge of the screen */
  ArrayList<Integer> toDelete = new  ArrayList<Integer>();

  for (int i = 0; i < cannonballs.size (); i++) {
    CannonBall cb1 = cannonballs.get(i);

    //attempt to check if cannonballs hits tanks
    if ( dist(cb1.position.x, cb1.position.y, ox1, oy1) < 30 ) {
      damageTank1 ++;
      glitchSound = 127;
      glitchBackground = 10;
    } 

    if ( dist(cb1.position.x, cb1.position.y, ox2, oy2) < 30 ) {
      damageTank2 ++;
      glitchSound = 127;
      glitchBackground = 10;
      
    } 




    if (cb1.position.y > height) {
      toDelete.add(i);
    } else {
      for (int j = i + 1; j < cannonballs.size (); j++) {
        CannonBall cb2 = cannonballs.get(j);
        float dist = sqrt(sq(cb1.position.y - cb2.position.y) + sq(cb1.position.x - cb2.position.x));
        if (dist< 80) {
          toDelete.add(i);
          toDelete.add(j);
          float aX = (cb1.position.x + cb2.position.x)/2;
          float aY = (cb1.position.y + cb2.position.y)/2;
          Explosion exp = new Explosion(aX, aY);
          explosions.add(exp);
          explosionTimer = 0;
          myBus.sendNoteOn(channel, exp.explosionPitch, noteVelocity); // Send a Midi noteOn
        }
      }
    }
  }

  glitchBackground--;
  
  if (glitchBackground <0) {
    glitchBackground=0;
  }

  glitchSound--;
  if (glitchSound < 0) {
    glitchSound=0;
  }

  //Restrain damage to tanks to be from 0-3
  if (damageTank1 > 3) {
    damageTank1 = 0;
  }
  if (damageTank2 > 3) {
    damageTank2 = 0;
  }

  //println(toDelete.size());
  for (int i = cannonballs.size ()-1; i >= 0; i--) {
    for (int j = 0; j < toDelete.size (); j++) {
      if (i == toDelete.get(j)) {
        // THIS IS GOING TO BE A PROBLEM IF THREE COLLIDE! fix that....
        cannonballs.remove(i);
      }
    }
  }

  //background(39, 40, 34);

  


  for (int i = 0; i < cannonballs.size (); i++) {
    cannonballs.get(i).draw();
  }

  for (int i = explosions.size () - 1; i >= 0; i--) {
    if (explosions.get(i).c<15) {
      explosions.get(i).draw();


      if (explosions.get(i).c==noteLength) {
        myBus.sendNoteOff(channel, explosions.get(i).explosionPitch, noteVelocity); // Send a Midi nodeOff
      }
    } else {
      explosions.remove(i);
    }
  }

  //drawOscTest();  




  for (int i = stars.size ()-1; i >= 0; i--) {
    Star star = stars.get(i);
    star.display();
    if (star.finished()) {
      // Items can be deleted with remove()
      stars.remove(i);
    }
  }

  //if (frameCount % 20 == 0) {
  sendOsc();
  displayTankDamage();


  //Smoke Particle System

  if (damageTank1 >0) {
    ps.run();
    if (frameCount % (4 -damageTank1) == 0) {
      for (int i = 0; i < 1; i++) {
        ps.addParticle(50*damageTank1);
      }
    }
  }
  strokeWeight(2);
  stroke(255, 200);
  fill(155);

  /* draw the cannons! */
  ellipse(ox1, oy1, 50, 50);
  ellipse(ox2, oy2, 50, 50);
  line(ox1, oy1, posx1, posy1);
  line(ox2, oy2, posx2, posy2);
}

public void readValues() {
  //angleCannon1 = (radians(random(90)));
  //angleCannon1 = 2 * PI - angleCannon1;
  angleCannon1 = 1.7*PI + sin(radians(mouseY));

  //  angleCannon2 = (radians(random(90)));
  //  angleCannon2 = PI + angleCannon2;
  angleCannon2 = 1.3*PI - sin(radians(mouseY));

  speedCannon1 = 40;
  speedCannon2 = 40;
} 

static int generateColor(float colorHeight, int screenHeight) {
  if (colorHeight < screenHeight/8 ) {
    return 0xFFFF8724; // orange
  }
  if (colorHeight < screenHeight/4 ) {
    return 0xFFF92672; // pink-red
  }
  if (colorHeight < 3*screenHeight/8 ) {
    return 0xFFDE5EE5; // pink-purple
  }
  if (colorHeight < screenHeight/2 ) {
    return 0xFFA176FF; // purple
  }
  if (colorHeight < 5*screenHeight/8 ) {
    return 0xFF6EA6FF; // purplish blue
  }
  if (colorHeight < 6*screenHeight/8 ) {
    return 0xFF66D9EF; // blue
  }
  if (colorHeight < 7*screenHeight/8 ) {
    return 0xFFA6E22D; // green
  } else {
    return 0xFFFFEB5A; // yellow
  }
}

void oscEvent(OscMessage theOscMessage) {
  /* check if theOscMessage has the address pattern we are looking for. */

  int notePitch = (int)map(pitchValue, 38, 70, TankNotesNoLib.canvasHeight/1.5, 50);

  if (theOscMessage.checkAddrPattern("velocity")==true || theOscMessage.checkAddrPattern("pitch")==true) {
    /* check if the typetag is the right one. */
    if (theOscMessage.checkTypetag("i")) {
      /* parse theOscMessage and extract the values from the osc message arguments. */
      int value = theOscMessage.get(0).intValue();  

      if (theOscMessage.addrPattern().equals("pitch") == true) {
        pitchValue = value;
        
      } else if (theOscMessage.addrPattern().equals("velocity") == true) {
        velValue = value;
        

        if (velValue > 0 && explosionTimer > 10) {

          stars.add(new Star(random(width), notePitch));
        }
      }
      return;
    }
  }
}


void sendOsc() {
  OscMessage myMessage = new OscMessage("/hitGlitch");
  myMessage.add(glitchSound); /* add an int to the osc message */

  /* send the message */
  oscP5.send(myMessage, myRemoteLocation);
}

void displayTankDamage() {
  textSize(32);
  text( damageTank1, 20, 50);
  text( damageTank2, width-20, 50);
}

