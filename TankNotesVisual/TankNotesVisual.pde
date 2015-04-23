import java.util.Iterator;
import processing.opengl.*;

import mathematik.*;

import teilchen.Particle;
import teilchen.BehaviorParticle;
import teilchen.Physics;
import teilchen.force.Gravity;

/**
* this sketch shows how to create and handle multiple particles and remove individual particles.
*/

Physics mPhysics;
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

void setup() {
	size(640, 480, OPENGL);
	smooth();
	frameRate(30);

	/* create a particle system */
	mPhysics = new Physics();

	/* create a gravitational force and add it to the particle system */
	Gravity myGravity = new Gravity(0, 50, 0);
	mPhysics.add(myGravity);

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
		if(clicking == false){
			/* create and add a particle to the system */
			Particle mParticle = mPhysics.makeParticle();
			/* set particle to mouse position with random velocity */
			if(mouseX < width/2){
				mParticle.position().set(posx1, posy1);
				mParticle.velocity().set(vx1, vy1);
			} else {
				mParticle.position().set(posx2, posy2);
				mParticle.velocity().set(vx2, vy2);
			}
		}
		clicking = true;
	}
	else{
		clicking = false;
	}

	/* update the particle system */
	final float mDeltaTime = 1.0 / frameRate;
	mPhysics.step(mDeltaTime);


	/* remove particles right before they hit the edge of the screen */
	ArrayList<Integer> toDelete = new  ArrayList<Integer>();
	
	for (int i = 0; i < mPhysics.particles().size(); i++) {
		Particle p1 = mPhysics.particles(i);
		if (p1.position().y > height * 0.9f) {
			toDelete.add(i);
		}
		else{
			for (int j = i + 1; j < mPhysics.particles().size(); j++) {
				Particle p2 = mPhysics.particles(j);
				float dist = sqrt(sq(p1.position().y - p2.position().y) + sq(p1.position().x - p2.position().x));
				if (dist< 30){
					toDelete.add(i);
					toDelete.add(j);
					float aX = (p1.position().x + p2.position().x)/2;
					float aY = (p1.position().y + p2.position().y)/2;
					Explosion exp = new Explosion(aX, aY);
					explosions.add(exp);
				}
			}
		}
	}

	//println(toDelete.size());
	for (int i = mPhysics.particles().size()-1; i >= 0; i--) {
		for(int j = 0; j < toDelete.size(); j++){
			if(i == toDelete.get(j)){
				// THIS IS GOING TO BE A PROBLEM IF THREE COLLIDE! fix that....
				mPhysics.particles().remove(i);
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


	for (int i = 0; i < mPhysics.particles().size(); i++) {
		Particle mParticle = mPhysics.particles(i);
		noStroke();
		//println("color: "+unhex(generateColor(mParticle.position().y, height)));
		fill(generateColor(mParticle.position().y, height));
		ellipse(mParticle.position().x, mParticle.position().y, 30, 30);
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

	speedCannon1 = 200;
	speedCannon2 = 200;
} 

static int generateColor(float colorHeight, int screenHeight){
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
