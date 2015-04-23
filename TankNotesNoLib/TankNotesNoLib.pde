
//OSC 
import oscP5.*;
import netP5.*;
OscP5 oscP5;
NetAddress myRemoteLocation;

int velValue;
int pitchValue;

//MIDI
import themidibus.*; //Import the library
MidiBus myBus; // The MidiBus

int channel = 1 ;
int noteVelocity = 127;


boolean clicking = false;

ArrayList<Explosion> explosions = new ArrayList<Explosion>();
ArrayList<CannonBall> cannonballs = new ArrayList<CannonBall>();

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

  //OSC: start oscP5, listening for incoming messages at port 12000 
  oscP5 = new OscP5(this, 12000);
  myRemoteLocation = new NetAddress("127.0.0.1", 12000);

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

          myBus.sendNoteOn(channel, exp.explosionPitch, noteVelocity); // Send a Midi noteOn
        }
      }
    }
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
  /* draw all the particles in the system */
  background(39, 40, 34);
  strokeWeight(2);
  stroke(255, 200);
  fill(255, 32);

  /* draw the cannons! */
  ellipse(ox1, oy1, 50, 50);
  ellipse(ox2, oy2, 50, 50);
  line(ox1, oy1, posx1, posy1);
  line(ox2, oy2, posx2, posy2);


  for (int i = 0; i < cannonballs.size (); i++) {
    cannonballs.get(i).draw();
  }

  for (int i = explosions.size () - 1; i >= 0; i--) {
    if (explosions.get(i).timer()) {
      explosions.get(i).draw();
    } else {


      myBus.sendNoteOff(channel, explosions.get(i).explosionPitch, noteVelocity); // Send a Midi nodeOff
      explosions.remove(i);
    }
  }

drawOscTest();  
}

public void readValues() {
  angleCannon1 = (radians(46));
  angleCannon1 = 2 * PI - angleCannon1;

  angleCannon2 = 2*PI/5;
  angleCannon2 = PI + angleCannon2;

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

  if (theOscMessage.checkAddrPattern("velocity")==true || theOscMessage.checkAddrPattern("pitch")==true) {
    /* check if the typetag is the right one. */
    if (theOscMessage.checkTypetag("i")) {
      /* parse theOscMessage and extract the values from the osc message arguments. */
      int value = theOscMessage.get(0).intValue();  

      if (theOscMessage.addrPattern().equals("pitch") == true) {
        pitchValue = value;
        println("pitch = " + pitchValue);
      } else if (theOscMessage.addrPattern().equals("velocity") == true) {
        velValue = value;
        println("velocity = " + value);
      }
      return;
    }
  }
}


void drawOscTest() {
pushStyle();
ellipse(pitchValue, pitchValue, velValue, velValue);
fill(255);
textAlign(CENTER);
text("pitch = " + pitchValue, pitchValue,pitchValue);
text("velocity = " + velValue, pitchValue,pitchValue+15);
popStyle();
}
