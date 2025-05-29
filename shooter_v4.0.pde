// === Asset Images ===
PImage playerImg, basicEnemyImg, advancedEnemyImg, veryAdvancedEnemyImg;
PImage playerBulletImg, advEnemyBulletImg, veryAdvEnemyBulletImg;
PImage collectableImg;

// === Game Objects ===
ArrayList<Bullet> bullets = new ArrayList<Bullet>();
ArrayList<Enemy> enemies = new ArrayList<Enemy>();
ArrayList<Explosion> explosions = new ArrayList<Explosion>();
ArrayList<Collectable> collectables = new ArrayList<Collectable>();
ArrayList<Star> stars = new ArrayList<Star>();
Player player;

// === Constants ===
final float SCALE = 2.5;
int shotgunCount = 1;
int enemySpawnCount = 100;

// === Game State ===
int lives = 6;
int maxLives = 6;
int score = 0;
boolean gameOver = false;
boolean gameStarted = false;
boolean paused = false;
boolean upgradeMenu = false;
PFont font;

// === Movement Keys State ===
boolean leftPressed = false;
boolean rightPressed = false;
boolean upPressed = false;
boolean downPressed = false;

// === Dynamic State ===
int enemiesKilled = 0;
float spawnInterval = 80;
float minSpawnInterval = 30;
float maxSpawnInterval = 120;
float spawnEaseFactor = 0.25;

// === Collectable Upgrade System ===
int collectableCount = 0;
int collectableGoal = 4;

void setup() {
  size(800, 600);
  frameRate(60);
  font = createFont("Arial", 32);
  textFont(font);

  playerImg = loadImage("Player.bmp");
  basicEnemyImg = loadImage("Basic Enemy.bmp");
  advancedEnemyImg = loadImage("Advanced Enemy.bmp");
  veryAdvancedEnemyImg = loadImage("Very Advanced Enemy.bmp");
  playerBulletImg = loadImage("Bullet.bmp");
  advEnemyBulletImg = loadImage("advanced_enemy_bullet.bmp");
  veryAdvEnemyBulletImg = loadImage("very_advanced_enemy_bullet.bmp");
  collectableImg = loadImage("lemon.bmp");

  player = new Player(width / 2, height - 100);

  // Initialize space background
  for (int i = 0; i < 150; i++) {
    stars.add(new Star());
  }
}

void draw() {
  drawSpaceBackground();

  if (!gameStarted) {
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(48);
    fill(255, 0, 0);
    text("SPACE INVADERS", width / 2, height / 2 - 40);
    textSize(24);
    fill(255);
    text("Press ENTER to Start", width / 2, height / 2 + 20);
    return;
  }

  if (upgradeMenu) {
    fill(255, 255, 0);
    textAlign(CENTER, CENTER);
    textSize(24);
    text("Collectable Goal Reached!", width / 2, height / 2 - 60);
    text("Press 1 to reset Health", width / 2, height / 2 - 20);
    text("Press 2 to increase Bullet Count", width / 2, height / 2 + 20);
    return;
  }

  if (paused) {
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(36);
    text("GAME PAUSED", width / 2, height / 2);
    return;
  }

  if (gameOver) {
    fill(255, 0, 0);
    textAlign(CENTER, CENTER);
    textSize(36);
    text("GAME OVER", width / 2, height / 2 - 30);
    textSize(24);
    fill(255);
    text("Final Score: " + score, width / 2, height / 2 + 13);
    text("Press R to Respawn", width / 2, height / 2 + 50);
    return;
  }

  player.update();
  player.display();

  for (int i = bullets.size() - 1; i >= 0; i--) {
    Bullet b = bullets.get(i);
    b.update();
    b.display();

    if (!(b.source instanceof Player) && dist(b.x, b.y, player.x, player.y) < player.getRadius() * 0.75) {
      explosions.add(new Explosion(b.x, b.y));
      bullets.remove(i);
      lives--;
      if (lives <= 0) gameOver = true;
      continue;
    }

    if (b.isOffscreen()) bullets.remove(i);
  }

  if (frameCount % enemySpawnCount == 0) spawnEnemies();

  for (int i = enemies.size() - 1; i >= 0; i--) {
    Enemy e = enemies.get(i);
    e.update();
    e.display();

    if (e.y > height + 50) {
      enemies.remove(i);
      continue;
    }

    e.shoot();

    if (e.checkCollision(player)) {
      explosions.add(new Explosion(e.x, e.y));
      enemies.remove(i);
      lives--;
      if (lives <= 0) gameOver = true;
      continue;
    }

    for (int j = bullets.size() - 1; j >= 0; j--) {
      Bullet b = bullets.get(j);
      if (e.checkBulletHit(b)) {
        e.hp--;
        bullets.remove(j);
        if (e.hp <= 0) {
          explosions.add(new Explosion(e.x, e.y));
          if (e instanceof BasicEnemy) {
            score += 1;
            if (random(1) < 1.0 / 8) collectables.add(new Collectable(e.x, e.y));
          } else if (e instanceof AdvancedEnemy) {
            score += 5;
            if (random(1) < 0.5) collectables.add(new Collectable(e.x, e.y));
          } else if (e instanceof VeryAdvancedEnemy) {
            score += 10;
            collectables.add(new Collectable(e.x, e.y));
          }
          enemies.remove(i);
          break;
        }
      }
    }
  }

  for (int i = explosions.size() - 1; i >= 0; i--) {
    Explosion ex = explosions.get(i);
    ex.update();
    ex.display();
    if (ex.finished()) explosions.remove(i);
  }

  for (int i = collectables.size() - 1; i >= 0; i--) {
    Collectable c = collectables.get(i);
    c.update();
    c.display();
    if (dist(c.x, c.y, player.x, player.y) < player.getRadius()) {
      collectables.remove(i);
      collectableCount++;

      if (collectableCount >= collectableGoal) {
        upgradeMenu = true;
        paused = true;
      }
    } else if (c.y > height + 20) {
      collectables.remove(i);
    }
  }

  // Draw HUD
  drawHealthBar();
  fill(255);
  textAlign(LEFT, TOP);
  textSize(20);
  text("Score: " + score, 10, 35);
  text("Collectables: " + collectableCount + "/" + collectableGoal, 10, 60);
}

void drawHealthBar() {
  int barWidth = 180;
  int barHeight = 8;
  int x = 10;
  int y = 10;

  float healthRatio = constrain((float)lives / maxLives, 0, 1);

  // Background
  noStroke();
  fill(60);
  rect(x, y, barWidth, barHeight, 10);

  // Foreground bar with a gradient from red to green
  color healthColor = lerpColor(color(255, 0, 0), color(0, 200, 0), healthRatio);
  fill(healthColor);
  rect(x, y, barWidth * healthRatio, barHeight, 10);

  noFill();
  stroke(255);
  strokeWeight(1);
  rect(x, y, barWidth, barHeight, 10);
}

void drawSpaceBackground() {
  background(0);
  for (Star s : stars) {
    s.update();
    s.display();
  }
}

// === Star Class for Space Effect ===
class Star {
  float x, y, speed, brightness;

  Star() {
    x = random(width);
    y = random(height);
    speed = random(1, 3);
    brightness = random(100, 255);
  }

  void update() {
    y += speed;
    if (y > height) {
      y = 0;
      x = random(width);
      speed = random(1, 3);
      brightness = random(100, 255);
    }
  }

  void display() {
    stroke(brightness);
    point(x, y);
  }
}

void keyPressed() {
  if (key == ESC) {
    key = 0;
    if (gameStarted && !gameOver && !upgradeMenu) {
      paused = !paused;
      if (paused) clearInput();
    }
    return;
  }

  if (!gameStarted && key == ENTER) {
    gameStarted = true;
    return;
  }

  if (gameOver && (key == 'r' || key == 'R')) {
    clearInput();
    gameOver = false;
    lives = maxLives;
    score = 0;
    bullets.clear();
    enemies.clear();
    explosions.clear();
    collectables.clear();
    collectableCount = 0;
    collectableGoal = 4;
    shotgunCount = 1;
    enemySpawnCount = 80;
    player = new Player(width / 2, height - 100);
    return;
  }

  if (upgradeMenu) {
    if (key == '1') {
      lives = maxLives;
    } else if (key == '2') {
      shotgunCount++;
    } else {
      return;
    }
    clearInput();
    collectableCount = 0;
    collectableGoal *= 2;
    enemySpawnCount = max(20, enemySpawnCount - 10);
    upgradeMenu = false;
    paused = false;
    return;
  }

  if (paused || !gameStarted || gameOver) return;

  if (key == ' ') {
    float angleSpread = PI / 10;
    float startAngle = -HALF_PI;
    if (shotgunCount > 1) startAngle -= angleSpread / 2;

    for (int i = 0; i < shotgunCount; i++) {
      float angle = startAngle + i * (angleSpread / max(shotgunCount - 1, 1));
      float speed = 5;
      float vx = cos(angle) * speed;
      float vy = sin(angle) * speed;
      bullets.add(new Bullet(player.x, player.y, vx, vy, playerBulletImg, player));
    }
  }

  if (keyCode == LEFT) leftPressed = true;
  if (keyCode == RIGHT) rightPressed = true;
  if (keyCode == UP) upPressed = true;
  if (keyCode == DOWN) downPressed = true;
}

void keyReleased() {
  if (paused || !gameStarted || gameOver) return;
  if (keyCode == LEFT) leftPressed = false;
  if (keyCode == RIGHT) rightPressed = false;
  if (keyCode == UP) upPressed = false;
  if (keyCode == DOWN) downPressed = false;
}

void clearInput() {
  leftPressed = false;
  rightPressed = false;
  upPressed = false;
  downPressed = false;
}

void spawnEnemies() {
  float rand = random(1);
  if (rand < 0.35) {
    float x = random(150, width - 150);
    float y = -40;
    float spacing = 50;
    enemies.add(new BasicEnemy(x, y));
    enemies.add(new BasicEnemy(x - spacing, y - spacing));
    enemies.add(new BasicEnemy(x + spacing, y - spacing));
    enemies.add(new BasicEnemy(x - 2 * spacing, y - 2 * spacing));
    enemies.add(new BasicEnemy(x + 2 * spacing, y - 2 * spacing));
  } else if (rand < 0.85) {
    float x = random(50, width - 50);
    enemies.add(new AdvancedEnemy(x, -40));
  } else {
    float x = random(50, width - 50);
    enemies.add(new VeryAdvancedEnemy(x, -40));
  }
}

// === Player Class ===
class Player {
  float x, y;
  float vx = 0, vy = 0;
  float speed = 5;

  Player(float x, float y) {
    this.x = x;
    this.y = y;
  }

  void update() {
    vx = 0;
    vy = 0;
    if (leftPressed) vx -= speed;
    if (rightPressed) vx += speed;
    if (upPressed) vy -= speed;
    if (downPressed) vy += speed;

    x += vx;
    y += vy;

    if (x < 0) x = 0;
    if (x > width) x = width;
    if (y < 0) y = 0;
    if (y > height) y = height;
  }

  void display() {
    imageMode(CENTER);
    image(playerImg, x, y, playerImg.width * SCALE, playerImg.height * SCALE);
  }

  float getRadius() {
    return max(playerImg.width, playerImg.height) * SCALE * 0.25;
  }
}

// === Bullet Class ===
class Bullet {
  float x, y, vx, vy;
  PImage img;
  Object source;

  Bullet(float x, float y, float vx, float vy, PImage img) {
    this(x, y, vx, vy, img, null);
  }

  Bullet(float x, float y, float vx, float vy, PImage img, Object source) {
    this.x = x;
    this.y = y;
    this.vx = vx;
    this.vy = vy;
    this.img = img;
    this.source = source;
  }

  void update() {
    x += vx;
    y += vy;
  }

  void display() {
    imageMode(CENTER);
    image(img, x, y);
  }

  boolean isOffscreen() {
    return y < -10 || y > height + 10 || x < -10 || x > width + 10;
  }
}

// === Explosion Class ===
class Explosion {
  float x, y;
  float radius = 10;
  float maxRadius = 40;
  int alpha = 255;

  Explosion(float x, float y) {
    this.x = x;
    this.y = y;
  }

  void update() {
    radius += 2;
    alpha -= 10;
  }

  void display() {
    noFill();
    stroke(255, alpha, 0, alpha);
    strokeWeight(2);
    ellipse(x, y, radius * 2, radius * 2);
  }

  boolean finished() {
    return alpha <= 0;
  }
}

// === Collectable Class ===
class Collectable {
  float x, y;
  float vy = 2;
  float size = 20;         // Size of the lemon and its hitbox
  float rotation = 0;      // Current rotation angle in radians
  float rotationSpeed = 5;     // How fast it spins

  Collectable(float x, float y) {
    this.x = x;
    this.y = y;
    this.rotationSpeed = random(-0.1, 0.1); // Random spin speed
  }

  void update() {
    y += vy;
    rotation += rotationSpeed;
  }

  void display() {
    pushMatrix();
    translate(x, y);
    rotate(rotation);
    imageMode(CENTER);
    image(collectableImg, 0, 0, size, size);
    popMatrix();
  }

  boolean isCollectedBy(Player p) {
    return dist(x, y, p.x, p.y) < (size / 2 + p.getRadius());
  }

  boolean isOffscreen() {
    return y > height + size;
  }
}



// === Enemy Base Class ===
abstract class Enemy {
  float x, y;
  int hp;
  PImage img;
  float vx = 0, vy = 0;

  Enemy(float x, float y, int hp, PImage img) {
    this.x = x;
    this.y = y;
    this.hp = hp;
    this.img = img;
  }

  abstract void update();
  abstract void shoot();

  void display() {
    float angle = atan2(vy, vx); // Direction of velocity
    pushMatrix();
    translate(x, y);
    rotate(angle - HALF_PI);
    imageMode(CENTER);
    image(img, 0, 0, img.width * SCALE, img.height * SCALE);
    popMatrix();
  }

  float getRadius() {
    return max(img.width, img.height) * SCALE * 0.4;
  }

  boolean checkCollision(Player p) {
    return dist(x, y, p.x, p.y) < (getRadius() + p.getRadius() * 0.15);
  }

  boolean checkBulletHit(Bullet b) {
    return b.source instanceof Player && dist(x, y, b.x, b.y) < getRadius();
  }
}

// === Basic Enemy ===
class BasicEnemy extends Enemy {
  BasicEnemy(float x, float y) {
    super(x, y, 4, basicEnemyImg);
  }

  void update() {
    y += 1.5;
  }

  void shoot() {
    // no shooting
  }
  
  void display() {
   imageMode(CENTER);
   image(img, x, y, img.width * SCALE, img.height * SCALE);
  }
}

// === Advanced Enemy ===
class AdvancedEnemy extends Enemy {
  int shootTimer = 0;

  AdvancedEnemy(float x, float y) {
    super(x, y, 8, advancedEnemyImg);
    float dx = player.x - x;
    float dy = player.y - y;
    float mag = sqrt(dx * dx + dy * dy);
    vx = dx / mag * 1.7;
    vy = dy / mag * 1.7;
  }

  void update() {
    x += vx;
    y += vy;
    shootTimer++;
  }

  
  void shoot() {
    if (y > 400) return;
    float bulletSpeed = 4.2;
    if (shootTimer > 60) {
      float dx = vx;
      float dy = vy;
      float mag = sqrt(dx * dx + dy * dy);
      if (mag == 0) return;
  
      dx = dx / mag * bulletSpeed;
      dy = dy / mag * bulletSpeed;
  
      bullets.add(new Bullet(x, y, dx, dy, advEnemyBulletImg, this));
      shootTimer = 0;
    }
  }


}

// === Very Advanced Enemy ===
class VeryAdvancedEnemy extends Enemy {
  int shootTimer = 0;

  VeryAdvancedEnemy(float x, float y) {
    super(x, y, 12, veryAdvancedEnemyImg);
    float dx = player.x - x;
    float dy = player.y - y;
    float mag = sqrt(dx * dx + dy * dy);
    vx = dx / mag * 1.35;
    vy = dy / mag * 1.35;
  }

  void update() {
    x += vx;
    y += vy;
    shootTimer++;
  }

  void shoot() {
    if (y > 400) return;
    if (shootTimer > 90) {
      float angle = atan2(player.y - y, player.x - x);
      float speed = 3.5;
      float spreadAngle = PI / 21;
      bullets.add(new Bullet(x, y, speed * cos(angle - spreadAngle), speed * sin(angle - spreadAngle), veryAdvEnemyBulletImg, this));
      bullets.add(new Bullet(x, y, speed * cos(angle + spreadAngle), speed * sin(angle + spreadAngle), veryAdvEnemyBulletImg, this));
      shootTimer = 0;
    }
  }
  
  void display() {
   imageMode(CENTER);
   image(img, x, y, img.width * SCALE, img.height * SCALE);
  }
}
