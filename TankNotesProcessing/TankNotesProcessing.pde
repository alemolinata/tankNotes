import processing.serial.*;
import oscP5.*;
import netP5.*;
import themidibus.*; //Import the library

Serial myPort;  // Create object from Serial class
String val;

// Cannons fired?
boolean fired = false;
boolean cannon1Fired = false;
boolean cannon2Fired = false;

ParticleSystem ps;
ParticleSystem ps2;

PImage bgImg;

PImage [] tankImgs = new PImage [4];
PImage tankCannon;

int damageTank1 = 0;
int damageTank2 = 0;

//OSC 

OscP5 oscP5;
NetAddress myRemoteLocation;

int velValue;
int pitchValue;
int glitchSound;
int glitchBackground;

//MIDI

MidiBus myBus; // The MidiBus



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
  println(Serial.list()[7]);
  myPort = new Serial(this, Serial.list()[7], 9600); 
  myPort.bufferUntil('\n');

  size(canvasWidth, canvasHeight, OPENGL);
  smooth();
  frameRate(30);

  //Lod Tanks

  for (int i = 0; i < tankImgs.length; i ++ ) {
    tankImgs[i] = loadImage( "tankNote_0" + i + ".png" );
  }

  tankCannon = loadImage("tankNote_cannon.png");



  bgImg = loadImage("Background_greyscale_lofi.jpg");


  //OSC: start oscP5, listening for incoming messages at port 12000 
  //oscP5 = new OscP5(this, 12000);
  //myRemoteLocation = new NetAddress("127.0.0.1", 9000);

  //MIDI
  //MidiBus.list(); // List all available Midi devices on STDOUT. This will show each device's index and name.
  //myBus = new MidiBus(this, 0, 1); // Create a new MidiBus using the device index to select the Midi input and output devices respectively.

  physicsCounter = millis();

  ox1 = 75;
  oy1 = height - 75;
  ox2 = width - 75;
  oy2 = oy1;

  //Smoke
  PImage img = loadImage("texture.png");
  ps = new ParticleSystem(0, new PVector(ox1, oy1-7), img);
  ps2 = new ParticleSystem(0, new PVector(ox2, oy2-7), img);
}

void draw() {

  image(bgImg, 0, 0);

  if (glitchBackground > 0) {

    pushStyle();
    fill(random(glitchBackground), glitchBackground);
    rect(0, 0, width, height);
    //filter(INVERT); 
    popStyle();
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

  if (fired) {
    if (clicking == false) {
      PVector mPosition = new PVector(0, 0);
      PVector mVelocity = new PVector(0, 0);
      if (cannon1Fired) {
        mPosition.set(posx1, posy1);
        mVelocity.set(vx1, vy1);
        cannon1Fired = false;
      } else if(cannon2Fired) {
        mPosition.set(posx2, posy2);
        mVelocity.set(vx2, vy2);
        cannon2Fired = false;
      }
      CannonBall mCannonBall = new CannonBall(mPosition, mVelocity);
      cannonballs.add(mCannonBall);
      clicking = true;
    }
    fired = false;
  } else {
    clicking = false;
  }

  /* remove particles right before they hit the edge of the screen */
  ArrayList<Integer> toDelete = new  ArrayList<Integer>();

  for (int i = 0; i < cannonballs.size (); i++) {
    CannonBall cb1 = cannonballs.get(i);

    //attempt to check if cannonballs hits tanks
    if ( dist(cb1.position.x, cb1.position.y, ox1, oy1) < 50 ) {
      damageTank1 ++;
      glitchSound = 127;
      glitchBackground = 155;
    } 

    if ( dist(cb1.position.x, cb1.position.y, ox2, oy2) < 50 ) {
      damageTank2 ++;
      glitchSound = 127;
      glitchBackground = 155;
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
          PVector mPositionVector = new PVector((cb1.position.x + cb2.position.x)/2, (cb1.position.y + cb2.position.y)/2);
          Explosion exp = new Explosion(mPositionVector, cannonballs.get(i).velocity, cannonballs.get(j).velocity);
          explosions.add(exp);
          explosionTimer = 0;

          myBus.sendNoteOn(channel, exp.explosionPitch, noteVelocity); // Send a Midi noteOn
          println("hello");
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
        cannonballs.remove(i);
        break;
      }
    }
  }

  //background(39, 40, 34);




  for (int i = 0; i < cannonballs.size (); i++) {
    cannonballs.get(i).draw();
  }

  for (int i = explosions.size () - 1; i >= 0; i--) {
    if (explosions.get(i).timer<15) {
      explosions.get(i).draw();
      if (explosions.get(i).timer == explosions.get(i).noteLength) {

        myBus.sendNoteOff(channel, explosions.get(i).explosionPitch, noteVelocity); // Send a Midi nodeOff
        print("goodbye");
        println(explosions.get(i).explosionPitch);
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


  if (damageTank2 >0) {
    ps2.run();
    if (frameCount % (4 -damageTank2) == 0) {
      for (int i = 0; i < 3; i++) {
        ps2.addParticle(50*damageTank2);
      }
    }
  }



  strokeWeight(2);
  stroke(255, 200);
  fill(155);

  /* draw the cannons! */
  //  ellipse(ox1, oy1, 50, 50);
  //  ellipse(ox2, oy2, 50, 50);
  //  line(ox1, oy1, posx1, posy1);
  //  line(ox2, oy2, posx2, posy2);

  pushStyle();
  imageMode(CENTER);
  image(tankImgs[damageTank1], ox1, oy1);
  image(tankImgs[damageTank2], ox2, oy2);

  pushMatrix();
  translate(ox1, oy1);
  //float a = atan2(posx1, posy1);
  rotate(angleCannon1);
  image(tankCannon, 0, 0);
  popMatrix();

  pushMatrix();
  translate(ox2, oy2);

  rotate(angleCannon2);
  image(tankCannon, 0, 0);
  popMatrix();




  popStyle();
}

public void readValues() {
  //  angleCannon1 = (radians(random(90)));
  //  angleCannon1 = 2 * PI - angleCannon1;
  angleCannon1 = 2*PI - map(mouseY, 0, height, PI/2, 0);

  //  angleCannon2 = (radians(random(90)));
  //  angleCannon2 = PI + angleCannon2;
  angleCannon2 = PI + map(mouseY, 0, height, PI/2, 0);

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

  int notePitch = (int)map(pitchValue, 38, 70, TankNotesProcessing.canvasHeight/1.5, 50);

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

  int tankTotal = damageTank1 + damageTank2;

  OscMessage myMessage = new OscMessage("/hitGlitch");
  myMessage.add(glitchSound); /* add an int to the osc message */
  myMessage.add(tankTotal);

  /* send the message */
  oscP5.send(myMessage, myRemoteLocation);
}

void displayTankDamage() {
  textSize(32);
  text( damageTank1, 20, 50);
  text( damageTank2, width-20, 50);
}

void serialEvent(Serial thisPort) { 
  try {
    // read the serial buffer:
    val = thisPort.readStringUntil('\n');

    if (val != null)
    {
      // trim the carrige return and linefeed from the input string:
      val = trim(val);

      // split the input string at the commas
      // and convert the sections into integers:
      float controllerInput[] = float(split(val, ','));

      // if we have received all the values, use them:
      if (controllerInput.length == 3) {
        fired = true;
        if (controllerInput[0] == 55552.0) {
          cannon1Fired = true;
          angleCannon1 = controllerInput[2];
          angleCannon1 = 360 - angleCannon1; 
          angleCannon1 = map(angleCannon1, 0, 360, 0, 2*PI);

          speedCannon1 = map(controllerInput[1], 0, 1000, 100, 10);
        } else if(controllerInput[0] == 66662.0) {
          cannon2Fired = true;
          angleCannon2 = controllerInput[2];
          angleCannon2 = 180 + angleCannon2; 
          angleCannon2 = map(angleCannon2, 0, 360, 0, 2*PI);

          speedCannon2 = map(controllerInput[1], 0, 1000, 100, 10);
        }
      } else if (controllerInput.length == 2) {
        if (controllerInput[0] == 55551.0) {
          angleCannon1 = controllerInput[1];
          angleCannon1 = 360 - angleCannon1; 
          angleCannon1 = map(angleCannon1, 0, 360, 0, 2*PI);
        } else if(controllerInput[0] == 66661.0) {
          angleCannon2 = controllerInput[1];
          angleCannon2 = 180 + angleCannon2; 
          angleCannon2 = map(angleCannon2, 0, 360, 0, 2*PI);
        }
      }
    }
  }
  catch(RuntimeException e) {
    e.printStackTrace();
  }
}
