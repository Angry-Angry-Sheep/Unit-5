ArrayList<Enemy> enemies;
PVector center;
float centerRadius = 40;
float defenderRadius = 20;

void setup() {
  size(800, 600);
  enemies = new ArrayList<Enemy>();
  center = new PVector(width/2, height/2);
}

void draw() {
  background(30);
  fill(0, 200, 0);
  noStroke();
  ellipse(center.x, center.y, centerRadius * 2, centerRadius * 2);

  // Draw defender
  fill(255);
  ellipse(mouseX, mouseY, defenderRadius * 2, defenderRadius * 2);

  // Update and draw enemies
  for (int i = enemies.size() - 1; i >= 0; i--) {
    Enemy e = enemies.get(i);
    e.update();
    e.display();
    e.checkCollisionWithDefender(new PVector(mouseX, mouseY), defenderRadius);
    if (e.reachedCenter(center, centerRadius)) {
      enemies.remove(i);
    }
  }

  // Occasionally spawn new enemies
  if (frameCount % 30 == 0) {
    enemies.add(new Enemy());
  }
}

// Enemy class
class Enemy {
  PVector pos, vel;
  float size = 20;

  Enemy() {
    // Spawn at random edge
    float side = random(4);
    float x, y;
    if (side < 1) { x = 0; y = random(height); }
    else if (side < 2) { x = width; y = random(height); }
    else if (side < 3) { x = random(width); y = 0; }
    else { x = random(width); y = height; }

    pos = new PVector(x, y);
    vel = PVector.sub(center, pos);
    vel.setMag(2); // Constant speed toward center
  }

  void update() {
    pos.add(vel);
  }

  void display() {
    fill(255, 0, 0);
    rectMode(CENTER);
    rect(pos.x, pos.y, size, size);
  }

  void checkCollisionWithDefender(PVector defenderPos, float defenderRadius) {
    float distToDefender = PVector.dist(pos, defenderPos);
    if (distToDefender < defenderRadius + size/2) {
      // Apply knockback: push away based on direction from defender
      PVector knockback = PVector.sub(pos, defenderPos);
      knockback.setMag(5);
      vel.add(knockback);
      vel.limit(6); // Limit speed after bounce
    }
  }

  boolean reachedCenter(PVector c, float cRadius) {
    return PVector.dist(pos, c) < cRadius;
  }
}
