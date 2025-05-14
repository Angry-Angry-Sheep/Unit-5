PVector p1, p2, ball;
PVector p1Velocity, p2Velocity, ballVelocity;

float playerSize = 50;
float ballSize = 20;
float speed = 3.5;
float friction = 0.99;
float goalSize = 200; // adjustable goal height

int p1Score = 0, p2Score = 0;

boolean[] keys = new boolean[128];
boolean up, down, left, right;

void setup() {
  size(800, 400);
  resetPositions();
}

void draw() {
  background(50, 150, 50);
  drawField();
  movePlayers();
  moveBall();
  checkCollision();
  checkGoal();
  drawPlayers();
  drawBall();
  drawScore();
}

void keyPressed() {
  if (key < 128) keys[key] = true;
  if (keyCode == UP) up = true;
  if (keyCode == DOWN) down = true;
  if (keyCode == LEFT) left = true;
  if (keyCode == RIGHT) right = true;
}

void keyReleased() {
  if (key < 128) keys[key] = false;
  if (keyCode == UP) up = false;
  if (keyCode == DOWN) down = false;
  if (keyCode == LEFT) left = false;
  if (keyCode == RIGHT) right = false;
}

void resetPositions() {
  p1 = new PVector(100, height/2);
  p2 = new PVector(width - 100, height/2);
  p1Velocity = new PVector(0, 0);
  p2Velocity = new PVector(0, 0);
  ball = new PVector(width/2, height/2);
  ballVelocity = new PVector(random(-3, 3), random(-2, 2));
}

void drawField() {
  stroke(255);
  line(width/2, 0, width/2, height);
  ellipse(width/2, height/2, 100, 100);
  noFill();
  rect(0, height/2 - goalSize/2, 10, goalSize);
  rect(width-10, height/2 - goalSize/2, 10, goalSize);
}

void movePlayers() {
  PVector oldP1 = p1.copy();
  p1Velocity.set(0, 0);
  if (keys['w']) p1Velocity.y = -speed;
  if (keys['s']) p1Velocity.y = speed;
  if (keys['a']) p1Velocity.x = -speed;
  if (keys['d']) p1Velocity.x = speed;
  p1.add(p1Velocity);
  if (!inBounds(p1, playerSize)) p1.set(oldP1);

  PVector oldP2 = p2.copy();
  p2Velocity.set(0, 0);
  if (up) p2Velocity.y = -speed;
  if (down) p2Velocity.y = speed;
  if (left) p2Velocity.x = -speed;
  if (right) p2Velocity.x = speed;
  p2.add(p2Velocity);
  if (!inBounds(p2, playerSize)) p2.set(oldP2);

  // Player collision + push with wall check
  float minDist = playerSize;
  PVector diff = PVector.sub(p1, p2);
  float dist = diff.mag();

  if (dist < minDist && dist > 0.001) {
    PVector push = diff.copy().normalize().mult((minDist - dist) / 2);
    PVector p1Test = PVector.add(p1, push);
    PVector p2Test = PVector.sub(p2, push);

    if (inBounds(p1Test, playerSize) && inBounds(p2Test, playerSize)) {
      p1 = p1Test;
      p2 = p2Test;
    } else if (inBounds(p1Test, playerSize)) {
      p1.add(push);
    } else if (inBounds(p2Test, playerSize)) {
      p2.sub(push);
    }
  }
}

boolean inBounds(PVector pos, float size) {
  return pos.x >= size/2 && pos.x <= width - size/2 &&
         pos.y >= size/2 && pos.y <= height - size/2;
}

void moveBall() {
  ball.add(ballVelocity);
  ballVelocity.mult(friction);

  // Top and bottom wall bounce
  if (ball.y < ballSize/2 || ball.y > height - ballSize/2) {
    ballVelocity.y *= -1;
    ball.y = constrain(ball.y, ballSize/2, height - ballSize/2);
  }

  // Side wall bounce (outside goal)
  if (ball.x < ballSize/2 && (ball.y < height/2 - goalSize/2 || ball.y > height/2 + goalSize/2)) {
    ballVelocity.x *= -1;
    ball.x = ballSize/2;
  }
  if (ball.x > width - ballSize/2 && (ball.y < height/2 - goalSize/2 || ball.y > height/2 + goalSize/2)) {
    ballVelocity.x *= -1;
    ball.x = width - ballSize/2;
  }
}

void checkCollision() {
  PVector toBall1 = PVector.sub(ball, p1);
  float dist1 = toBall1.mag();
  float minDist1 = (playerSize + ballSize) / 2;
  if (dist1 < minDist1 && dist1 > 0.01) {
    PVector push = toBall1.copy().normalize().mult(minDist1 - dist1);
    ball.add(push);
    PVector reflect = toBall1.copy().normalize().mult(4);
    ballVelocity = reflect;
  }

  PVector toBall2 = PVector.sub(ball, p2);
  float dist2 = toBall2.mag();
  float minDist2 = (playerSize + ballSize) / 2;
  if (dist2 < minDist2 && dist2 > 0.01) {
    PVector push = toBall2.copy().normalize().mult(minDist2 - dist2);
    ball.add(push);
    PVector reflect = toBall2.copy().normalize().mult(4);
    ballVelocity = reflect;
  }
}

void checkGoal() {
  if (ball.x < 10 && ball.y > height/2 - goalSize/2 && ball.y < height/2 + goalSize/2) {
    p2Score++;
    resetPositions();
  }
  if (ball.x > width - 10 && ball.y > height/2 - goalSize/2 && ball.y < height/2 + goalSize/2) {
    p1Score++;
    resetPositions();
  }
}

void drawPlayers() {
  fill(0, 0, 255);
  ellipse(p1.x, p1.y, playerSize, playerSize);
  fill(255, 0, 0);
  ellipse(p2.x, p2.y, playerSize, playerSize);
}

void drawBall() {
  fill(255, 255, 0);
  ellipse(ball.x, ball.y, ballSize, ballSize);
}

void drawScore() {
  fill(255);
  textSize(20);
  textAlign(CENTER);
  text("Blue: " + p1Score, width/4, 30);
  text("Red: " + p2Score, width*3/4, 30);
}
