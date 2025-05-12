// Ball and paddle variables
float maxSpeed = 12;
float ampVelocity = 1;
float paddleWidth = 15;
float paddleHeight = 85;

// Player paddles
float p1X, p1Y;
float p2X, p2Y;

// Score
int p1Score = 0;
int p2Score = 0;

// Bricks
int brickCols = 4;
int brickRows;
float brickW = 20;
float brickH = 20;
boolean[][] p1Bricks;
boolean[][] p2Bricks;
float brickMargin = 30;

// Key tracking
int player1Movement = 0;
int player2Movement = 0;

// Ball array
ArrayList<Ball> balls = new ArrayList<Ball>();

// Timing
int lastBallTime = 0;
int ballInterval = 50; // 5 seconds

boolean resetGameLater;

class Ball {
  public float ballX, ballY;
  public float ballSpeedX = 4;
  public float ballSpeedY = 3;
  public float ballSize = 20;
  
  public Ball(float speed) {
    ballX = width / 2;
    ballY = height / 2;
    ballSpeedX = random(1) > 0.5 ? speed : -speed;
    ballSpeedY = random(-3, 3);
  }
  
  public void ballTick() {
    ellipse(ballX, ballY, ballSize, ballSize);
    ballX += ballSpeedX;
    ballY += ballSpeedY;
    
    if (ballY <= 0 || ballY >= height)
      ballSpeedY *= -1;
      
    if (ballX + ballSize / 2 > p1X && ballX - ballSize / 2 < p1X + paddleWidth &&
    ballY + ballSize / 2 > p1Y && ballY - ballSize / 2 < p1Y + paddleHeight) {
      if (ballSpeedX < 0) {
        ballSpeedX *= -ampVelocity;
        ballSpeedY -= player1Movement * 2;
        ballSpeedY += random(-0.5, 0.5);
        ballX = p1X + paddleWidth + ballSize / 2;
        clampBallSpeed(this);
      } else {
        ballSpeedX *= -1;
        ballX = p1X - ballSize / 2;
      }
    }
    
    if (ballX + ballSize / 2 > p2X && ballX - ballSize / 2 < p2X + paddleWidth &&
        ballY + ballSize / 2 > p2Y && ballY - ballSize / 2 < p2Y + paddleHeight) {
      if (ballSpeedX > 0) {
        ballSpeedX *= -ampVelocity;
        ballSpeedY -= player2Movement * 2;
        ballSpeedY += random(-0.5, 0.5);
        ballX = p2X - ballSize / 2;
        clampBallSpeed(this);
      } else {
        ballSpeedX *= -1;
        ballX = p2X + paddleWidth + ballSize / 2;
      }
    }

    // Game over if ball touches edge
    if (ballX + ballSize / 2 < 0) {
      p2Score++;
      resetGameLater = true;
      return;
    }
    if (ballX - ballSize / 2 > width) {
      p1Score++;
      resetGameLater = true;
      return;
    }

    checkBrickCollision(this);
  }
}

void setup() {
  size(800, 400);
  balls.add(new Ball(random(1)+4));
  
  p1X = brickMargin + brickCols * brickW + 10;
  p2X = width - brickMargin - brickCols * brickW - 10 - paddleWidth;
  p1Y = height / 2 - paddleHeight / 2;
  p2Y = height / 2 - paddleHeight / 2;

  brickRows = int(height / brickH);
  p1Bricks = new boolean[brickCols][brickRows];
  p2Bricks = new boolean[brickCols][brickRows];

  for (int i = 0; i < brickCols; i++) {
    for (int j = 0; j < brickRows; j++) {
      p1Bricks[i][j] = true;
      p2Bricks[i][j] = true;
    }
  }
  lastBallTime = millis(); // initialize timer
}

void draw() {
  background(0);
  
  for (Ball b : balls)
    b.ballTick();
  
  if (resetGameLater == true) {
    resetGame();
    resetGameLater = false;
  }

  drawBricks(p1Bricks, brickMargin);
  drawBricks(p2Bricks, width - brickMargin - brickCols * brickW);

  fill(255);
  rect(p1X, p1Y, paddleWidth, paddleHeight);
  rect(p2X, p2Y, paddleWidth, paddleHeight);

  textSize(32);
  textAlign(CENTER, TOP);
  text(p1Score + " : " + p2Score, width / 2, 10);

  if (player1Movement == 1) p1Y -= 7.5;
  if (player1Movement == -1) p1Y += 7.5;
  if (player2Movement == 1) p2Y -= 7.5;
  if (player2Movement == -1) p2Y += 7.5;

  p1Y = constrain(p1Y, 0, height - paddleHeight);
  p2Y = constrain(p2Y, 0, height - paddleHeight);

  // Spawn a new ball every few seconds
  if (millis() - lastBallTime > ballInterval) {
    balls.add(new Ball(random(1) + 4));
    lastBallTime = millis();
  }
}

void drawBricks(boolean[][] bricks, float startX) {
  for (int i = 0; i < brickCols; i++) {
    for (int j = 0; j < brickRows; j++) {
      if (bricks[i][j]) {
        float x = startX + i * brickW;
        float y = j * brickH;
        rect(x, y, brickW, brickH);
      }
    }
  }
}

void checkBrickCollision(Ball b) {
  float p1StartX = brickMargin;
  for (int i = 0; i < brickCols; i++) {
    for (int j = 0; j < brickRows; j++) {
      if (p1Bricks[i][j]) {
        float x = p1StartX + i * brickW;
        float y = j * brickH;
        if (b.ballX + b.ballSize / 2 > x &&
            b.ballX - b.ballSize / 2 < x + brickW &&
            b.ballY + b.ballSize / 2 > y &&
            b.ballY - b.ballSize / 2 < y + brickH) {
          p1Bricks[i][j] = false;
          b.ballSpeedX *= -ampVelocity;
          clampBallSpeed(b);
          return;
        }
      }
    }
  }

  float p2StartX = width - brickMargin - brickCols * brickW;
  for (int i = 0; i < brickCols; i++) {
    for (int j = 0; j < brickRows; j++) {
      if (p2Bricks[i][j]) {
        float x = p2StartX + i * brickW;
        float y = j * brickH;
        if (b.ballX + b.ballSize / 2 > x &&
            b.ballX - b.ballSize / 2 < x + brickW &&
            b.ballY + b.ballSize / 2 > y &&
            b.ballY - b.ballSize / 2 < y + brickH) {
          p2Bricks[i][j] = false;
          b.ballSpeedX *= -ampVelocity;
          clampBallSpeed(b);
          return;
        }
      }
    }
  }
}

void clampBallSpeed(Ball b) {
  float speedMag = dist(0, 0, b.ballSpeedX, b.ballSpeedY);
  if (speedMag > maxSpeed) {
    float angle = atan2(b.ballSpeedY, b.ballSpeedX);
    b.ballSpeedX = cos(angle) * maxSpeed;
    b.ballSpeedY = sin(angle) * maxSpeed;
  }
}

void resetGame() {
  balls.clear();
  balls.add(new Ball(random(1) + 4));

  p1Y = height / 2 - paddleHeight / 2;
  p2Y = height / 2 - paddleHeight / 2;

  for (int i = 0; i < brickCols; i++) {
    for (int j = 0; j < brickRows; j++) {
      p1Bricks[i][j] = true;
      p2Bricks[i][j] = true;
    }
  }

  lastBallTime = millis();
}

void keyPressed() {
  if (key == 'w' || key == 'W') player1Movement = 1;
  if (key == 's' || key == 'S') player1Movement = -1;
  if (keyCode == UP) player2Movement = 1;
  if (keyCode == DOWN) player2Movement = -1;
}

void keyReleased() {
  if (key == 'w' || key == 'W') player1Movement = 0;
  if (key == 's' || key == 'S') player1Movement = 0;
  if (keyCode == UP) player2Movement = 0;
  if (keyCode == DOWN) player2Movement = 0;
}
