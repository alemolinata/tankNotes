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
		ellipse(position.x, position.y, 50, 50);
	}
}
