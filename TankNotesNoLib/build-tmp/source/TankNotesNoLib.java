import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class TankNotesNoLib extends PApplet {

/**
* this sketch shows how to create and handle multiple particles and remove individual particles.
*/
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

static final PVector gravity = new PVector(0,1);

public void setup() {
	size(1400, 800, OPENGL);
	smooth();
	frameRate(30);

	physicsCounter = millis();

	ox1 = 50;
	oy1 = height - 50;
	ox2 = width - 50;
	oy2 = oy1;

}

public void draw() {
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
		if(clicking == false){
			PVector mPosition = new PVector(0, 0);
			PVector mVelocity = new PVector(0, 0);
			if(mouseX < width/2){
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
	}
	else{
		clicking = false;
	}


	/* remove particles right before they hit the edge of the screen */
	ArrayList<Integer> toDelete = new  ArrayList<Integer>();
	
	for (int i = 0; i < cannonballs.size(); i++) {
		CannonBall cb1 = cannonballs.get(i);
		if (cb1.position.y > height * 0.9f) {
			toDelete.add(i);
		}
		else{
			for (int j = i + 1; j < cannonballs.size(); j++) {
				CannonBall cb2 = cannonballs.get(j);
				float dist = sqrt(sq(cb1.position.y - cb2.position.y) + sq(cb1.position.x - cb2.position.x));
				if (dist< 30){
					toDelete.add(i);
					toDelete.add(j);
					float aX = (cb1.position.x + cb2.position.x)/2;
					float aY = (cb1.position.y + cb2.position.y)/2;
					Explosion exp = new Explosion(aX, aY);
					explosions.add(exp);
				}
			}
		}
	}

	//println(toDelete.size());
	for (int i = cannonballs.size()-1; i >= 0; i--) {
		for(int j = 0; j < toDelete.size(); j++){
			if(i == toDelete.get(j)){
				// THIS IS GOING TO BE A PROBLEM IF THREE COLLIDE! fix that....
				cannonballs.remove(i);
			}
		}
	}
	/* draw all the particles in the system */
	background(39,40,34);
	strokeWeight(2);
	stroke(255, 200);
	fill(255, 32);

	/* draw the cannons! */
	ellipse(ox1, oy1, 50, 50);
	ellipse(ox2, oy2, 50, 50);
	line(ox1, oy1, posx1, posy1);
	line(ox2, oy2, posx2, posy2);


	for (int i = 0; i < cannonballs.size(); i++) {
		cannonballs.get(i).draw();
	}
	
	for (int i = explosions.size() - 1; i >= 0; i--) {
		if(explosions.get(i).timer()){
			explosions.get(i).draw();
		}
		else{
			explosions.remove(i);
		}
	}
}

public void readValues(){
	angleCannon1 = PI/4;
	angleCannon1 = 2 * PI - angleCannon1;
	
	angleCannon2 = PI/4;
	angleCannon2 = PI + angleCannon2;

	speedCannon1 = 40;
	speedCannon2 = 40;
} 

public static int generateColor(float colorHeight, int screenHeight){
	if (colorHeight < screenHeight/8 ){
		return 0xFFFF8724; // orange
	}
	if (colorHeight < screenHeight/4 ){
		return 0xFFF92672; // pink-red
	}
	if (colorHeight < 3*screenHeight/8 ){
		return 0xFFDE5EE5; // pink-purple
	}
	if (colorHeight < screenHeight/2 ){
		return 0xFFA176FF; // purple
	}
	if (colorHeight < 5*screenHeight/8 ){
		return 0xFF6EA6FF; // purplish blue
	}
	if (colorHeight < 6*screenHeight/8 ){
		return 0xFF66D9EF; // blue
	}
	if (colorHeight < 7*screenHeight/8 ){
		return 0xFFA6E22D; // green
	}
	else{
		return 0xFFFFEB5A; // yellow
	}
}
class CannonBall{
	public PVector position = new PVector(0, 0);
	public PVector velocity = new PVector(0, 0);

	int initX;
	int initY;

	int velX;
	int velY;
	
	public CannonBall( PVector initPos, PVector initVel ) {
		super();
		position.set(initPos);
		velocity.set(initVel);
	}

	public void draw(){
		velocity.add(TankNotesNoLib.gravity);
		position.add(velocity);
		noStroke();
		fill(TankNotesNoLib.generateColor(position.y, height));
		ellipse(position.x, position.y, 20, 20);
	}
}
class Explosion{
	
	float initX;
	float initY;

	int c = 0;
	
	public Explosion( float initialX, float initialY ) {
		super();
		initX = initialX;
		initY = initialY;
	}
	
	public boolean timer(){
		if (c<15){
			return true;
		}
		else{
			return false;
		}
	}
	
	public void draw(){
		noStroke();
		fill(TankNotesNoLib.generateColor(initY, height)-c*0x0F000000);
		ellipse(initX, initY, c*c, c*c);
		c++;
	}
}
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "TankNotesNoLib" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
