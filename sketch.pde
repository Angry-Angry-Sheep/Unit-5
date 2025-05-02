// Ball variables
float ballX, ballY;
float ballSpeedX = 4;
float ballSpeedY = 3;
float ballSize = 20;

// Paddle variables
float paddleWidth = 15;
float paddleHeight = 100;

// Player 1 paddle
float p1X = 20;
float p1Y;

// Player 2 paddle
float p2X;
float p2Y;

// Score
int p1Score = 0;
int p2Score = 0;

void setup() {
  size(800, 400);
  resetBall();
  p1Y = height / 2 - paddleHeight / 2;
  p2X = width - paddleWidth - 20;
  p2Y = height / 2 - paddleHeight / 2;
}

void draw() {
  background(0);
  fill(255);
  
  // Draw ball
  ellipse(ballX, ballY, ballSize, ballSize);
  
  // Draw paddles
  rect(p1X, p1Y, paddleWidth, paddleHeight);
  rect(p2X, p2Y, paddleWidth, paddleHeight);
  
  // Draw score
  textSize(32);
  textAlign(CENTER, TOP);
  text(p1Score + " : " + p2Score, width / 2, 10);
  
  // Move ball
  ballX += ballSpeedX;
  ballY += ballSpeedY;
  
  // Bounce off top and bottom
  if (ballY <= 0 || ballY >= height) {
    ballSpeedY *= -1;
  }
  
  // Player 1 controls
  if (keyPressed) {
    if (key == 'w' || key == 'W') p1Y -= 5;
    if (key == 's' || key == 'S') p1Y += 5;
  }
  
  // Player 2 controls
  if (keyPressed) {
    if (keyCode == UP) p2Y -= 5;
    if (keyCode == DOWN) p2Y += 5;
  }
  
  // Keep paddles on screen
  p1Y = constrain(p1Y, 0, height - paddleHeight);
  p2Y = constrain(p2Y, 0, height - paddleHeight);
  
  // Paddle collision
  if (ballX - ballSize/2 < p1X + paddleWidth && 
      ballY > p1Y && ballY < p1Y + paddleHeight) {
    ballSpeedX *= -1;
    ballX = p1X + paddleWidth + ballSize/2;
  }
  
  if (ballX + ballSize/2 > p2X && ballY > p2Y && ballY < p2Y + paddleHeight) {
    ballSpeedX *= -1.1;
    ballSpeedY += random(-2,2.0);
    ballX = p2X - ballSize/2;
  }
  
  // Scoring
  if (ballX < 0) {
    p2Score++;
    resetBall();
  } else if (ballX > width) {
    p1Score++;
    resetBall();
  }
}

void resetBall() {
  ballX = width / 2;
  ballY = height / 2;
  ballSpeedX = random(1) > 0.5 ? 4 : -4;
  ballSpeedY = random(-3, 3);
}
