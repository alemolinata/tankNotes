import teilchen.Particle;
import teilchen.Physics;
import teilchen.force.Gravity;

class CannonBall extends BehaviorParticle {
	
	int initX;
	int initY;

	int velX;
	int velY;
	
	public CannonBall( int initialX, int initialY, int velocityX, int velocityY ) {
		super();
		initX = initialX;
		initY = initialY;
		velX = velocityX;
		velY = velocityY;
	}

	public void draw(){
		ellipse(this.position().x, this.position().y, 60, 60);
	}
}