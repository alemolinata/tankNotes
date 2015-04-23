class Star {

  float x;
  float y;
  float life = 255;
  float w = 20;
  

  Star(float tempX, float tempY) {
    
    x = tempX;
    y = tempY;
    
  }

  boolean finished() {
    // Stars fade out
    life = life - 10;
    if (life < 0) {
      return true;
    } else {
      return false;
    }
  }

  void display()
  {
    noStroke();
    fill (255, life);
    
    pushMatrix();
    translate(x, y);
    rotate(sin(frameCount / 50.0));
    
    drawStar(0, 0, 10, 20, 16); 
    //ellipse(x, y, w, w);
     popMatrix();
  }


void drawStar(float x, float y, float radius1, float radius2, int npoints) {
  float angle = TWO_PI / npoints;
  float halfAngle = angle/2.0;
  beginShape();
  for (float a = 0; a < TWO_PI; a += angle) {
    float sx = x + cos(a) * radius2;
    float sy = y + sin(a) * radius2;
    vertex(sx, sy);
    sx = x + cos(a+halfAngle) * radius1;
    sy = y + sin(a+halfAngle) * radius1;
    vertex(sx, sy);
  }
  endShape(CLOSE);
}
}
