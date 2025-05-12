ArrayList<Enemy> enemies;
ArrayList<PurpleEnemy> purpleEnemies;  // List to store purple enemies
PVector center;
float centerRadius = 40;
float defenderRadius = 20;
PVector lastMousePos;
boolean gravityEnabled = false;  // Toggle to enable/disable gravity after hit

int spawnRate = 70;  // Initial spawn rate (frames between each spawn)
int minSpawnRate = 30;  // Minimum spawn rate (fastest spawn speed)
int maxSpawnRate = 20;  // Maximum spawn rate (fastest possible spawn)
int spawnTimer = 0;  // Timer to control spawn rate

void setup() {
  size(800, 600);
  enemies = new ArrayList<Enemy>();
  purpleEnemies = new ArrayList<PurpleEnemy>();  // Initialize purple enemies
  center = new PVector(width/2, height/2);
  lastMousePos = new PVector(mouseX, mouseY);
}

void draw() {
  background(30);

  // Draw green "Earth"
  fill(0, 200, 0);
  noStroke();
  ellipse(center.x, center.y, centerRadius * 2, centerRadius * 2);

  // Draw white defender
  fill(255);
  ellipse(mouseX, mouseY, defenderRadius * 2, defenderRadius * 2);

  // Update and draw enemies
  for (int i = enemies.size() - 1; i >= 0; i--) {
    Enemy e = enemies.get(i);
    e.update();
    e.display();
    e.checkCollisionWithDefender(lastMousePos, new PVector(mouseX, mouseY), defenderRadius);
    if (e.reachedCenter(center, centerRadius)) {
      enemies.remove(i);
    }
  }

  // Update and draw purple enemies
  for (int i = purpleEnemies.size() - 1; i >= 0; i--) {
    PurpleEnemy p = purpleEnemies.get(i);
    p.update();
    p.display();
    p.checkCollisionWithDefender(lastMousePos, new PVector(mouseX, mouseY), defenderRadius);
    if (p.number <= 0) {
      purpleEnemies.remove(i);
    }
  }

  // Increment spawn timer
  spawnTimer++;

  // Occasionally spawn new enemies, with the spawn rate becoming faster
  if (spawnTimer >= spawnRate) {
    spawnTimer = 0;  // Reset the spawn timer

    // Spawn a purple enemy with a 5% chance
    if (random(1) < 0.5) {
      purpleEnemies.add(new PurpleEnemy());
    } else {
      enemies.add(new Enemy());  // Regular red enemy
    }

    // Gradually increase the spawn rate speed until it reaches the maximum
    if (spawnRate > maxSpawnRate) {
      spawnRate--;  // Make spawn rate faster by decreasing the interval
    }
  }

  // Update last mouse position
  lastMousePos.set(mouseX, mouseY);
}

// Enemy class (Base class for all enemies)
class Enemy {
  PVector pos;
  PVector baseVel;     // constant velocity toward center
  PVector extraVel;    // temporary knockback velocity
  float size = 20;
  float friction = 0.95;
  float maxSpeed = 6;
  boolean wasDeflected = false;

  Enemy() {
    float side = random(4);
    float x, y;
    if (side < 1) { x = 0; y = random(height); }
    else if (side < 2) { x = width; y = random(height); }
    else if (side < 3) { x = random(width); y = 0; }
    else { x = random(width); y = height; }

    pos = new PVector(x, y);
    baseVel = PVector.sub(center, pos);
    baseVel.setMag(2);
    extraVel = new PVector(0, 0);
  }

  void update() {
    if (gravityEnabled && wasDeflected) {
      // Gravity: reapply attraction to center
      PVector gravity = PVector.sub(center, pos);
      gravity.setMag(0.1);
      extraVel.add(gravity);
    }

    // Clamp knockback speed after adding gravity, no friction applied
    if (extraVel.mag() > maxSpeed) {
      extraVel.setMag(maxSpeed);
    }

    pos.add(PVector.add(baseVel, extraVel));
  }

  void display() {
    fill(255, 0, 0);
    rectMode(CENTER);
    rect(pos.x, pos.y, size, size);
  }

  void checkCollisionWithDefender(PVector lastMouse, PVector currMouse, float defenderRadius) {
    float distToDefender = PVector.dist(pos, currMouse);
    if (distToDefender < defenderRadius + size / 2) {
      // Calculate the vector from the defender to the enemy (collision normal)
      PVector normal = PVector.sub(pos, currMouse);
      normal.normalize();
      
      // Calculate the overlap
      float overlap = (defenderRadius + size / 2) - distToDefender;
      
      // no clipping
      pos.add(PVector.mult(normal, overlap));

      // Calculate and apply the impulse
      PVector defenderVelocity = PVector.sub(currMouse, lastMouse);
      PVector impulse = PVector.sub(pos, currMouse);
      impulse.normalize();
      impulse.mult(defenderVelocity.mag() * 0.8);
      extraVel.add(impulse);

      // Ensure the velocity does not go beyond maxSpeed
      if (extraVel.mag() > maxSpeed) {
        extraVel.setMag(maxSpeed);
      }

      // Set that the enemy was deflected
      wasDeflected = true;
    }
  }

  boolean reachedCenter(PVector c, float cRadius) {
    return PVector.dist(pos, c) < cRadius;
  }
}

class PurpleEnemy extends Enemy {
  int number = 3;
  float size = 30;

  PurpleEnemy() {
    super();
    extraVel.setMag(4);  // Initial velocity
  }

  @Override
  void display() {
    fill(128, 0, 128);
    rectMode(CENTER);
    rect(pos.x, pos.y, size, size);

    // Draw the number on the enemy
    fill(255);
    textSize(16);
    textAlign(CENTER, CENTER);
    text(number, pos.x, pos.y);
  }

  @Override
  void update() {
    super.update();

    // Bounce on the edges and decrease the number when bouncing
    if (pos.x - size / 2 < 0 || pos.x + size / 2 > width) {
      extraVel.x *= -1;  // Reverse horizontal velocity
      number--;  // Decrease number when bouncing off the edge
    }
    if (pos.y - size / 2 < 0 || pos.y + size / 2 > height) {
      extraVel.y *= -1;  // Reverse vertical velocity
      number--;  // Decrease number when bouncing off the edge
    }
  }

  @Override
  void checkCollisionWithDefender(PVector lastMouse, PVector currMouse, float defenderRadius) {
    super.checkCollisionWithDefender(lastMouse, currMouse, defenderRadius);  // Call the base method
  }
}
