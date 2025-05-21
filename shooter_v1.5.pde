// === Asset Images ===
PImage playerImg, basicEnemyImg, advancedEnemyImg, veryAdvancedEnemyImg;
PImage playerBulletImg, advEnemyBulletImg, veryAdvEnemyBulletImg;

// === Game Objects ===
ArrayList<Bullet> bullets = new ArrayList<Bullet>();
ArrayList<Enemy> enemies = new ArrayList<Enemy>();
ArrayList<Explosion> explosions = new ArrayList<Explosion>();
Player player;

// === Constants ===
final float SCALE = 2.5;
final float SHOOT_DISABLE_Y = 500;
int shotgunCount = 1; // Number of bullets per shotgun shot
int enemySpawnCount = 90;

// === Game State ===
int lives = 4;
int score = 0;
boolean gameOver = false;
PFont font;

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

  player = new Player(width / 2, height - 100);
}

void draw() {
  background(0);

  if (gameOver) {
    fill(255, 0, 0);
    textAlign(CENTER, CENTER);
    text("GAME OVER", width / 2, height / 2);
    textSize(24);
    fill(255);
    text("Press R to Respawn", width / 2, height / 2 + 40);
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

    // Remove enemies that move off the screen (bottom)
    if (e.y > height + 50) {
      enemies.remove(i);
      continue;
    }

    if (e.y < SHOOT_DISABLE_Y) e.shoot();

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
          if (e instanceof BasicEnemy) score += 1;
          else if (e instanceof AdvancedEnemy) score += 5;
          else if (e instanceof VeryAdvancedEnemy) score += 10;
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

  fill(255);
  textAlign(LEFT, TOP);
  textSize(20);
  text("Lives: " + lives, 10, 10);
  text("Score: " + score, 10, 35);
}

void keyPressed() {
  if (gameOver && (key == 'r' || key == 'R')) {
    gameOver = false;
    lives = 4;
    score = 0;
    bullets.clear();
    enemies.clear();
    explosions.clear();
    player = new Player(width / 2, height - 100);
    return;
  }

  if (gameOver) return;

  if (key == ' ') {
    float angleSpread = PI / 10;
    float startAngle = -HALF_PI - angleSpread / 2;
    for (int i = 0; i < shotgunCount; i++) {
      float angle = startAngle + i * (angleSpread / max(shotgunCount - 1, 1));
      float speed = 5;
      float vx = cos(angle) * speed;
      float vy = sin(angle) * speed;
      bullets.add(new Bullet(player.x, player.y, vx, vy, playerBulletImg, player));
    }
  }

  if (keyCode == LEFT) player.vx = -player.speed;
  if (keyCode == RIGHT) player.vx = player.speed;
}

void spawnEnemies() {
  float rand = random(1);

  if (rand < 0.6) {
    float x = random(150, width - 150);
    float y = -40;
    float spacing = 50;
    enemies.add(new BasicEnemy(x, y));
    enemies.add(new BasicEnemy(x - spacing, y - spacing));
    enemies.add(new BasicEnemy(x + spacing, y - spacing));
    enemies.add(new BasicEnemy(x - 2 * spacing, y - 2 * spacing));
    enemies.add(new BasicEnemy(x + 2 * spacing, y - 2 * spacing));
  } else if (rand < 0.90) {
    float x = random(50, width - 50);
    enemies.add(new AdvancedEnemy(x, -40));
  } else {
    float x = random(50, width - 50);
    enemies.add(new VeryAdvancedEnemy(x, -40));
  }
}

// === Player ===
class Player {
  float x, y;
  float vx = 0;
  float speed = 5;

  Player(float x, float y) {
    this.x = x;
    this.y = y;
  }

  void update() {
    x += vx;
    if (x < 0 || x > width) {
      vx = -vx;
      x = constrain(x, 0, width);
    }
  }

  void display() {
    imageMode(CENTER);
    image(playerImg, x, y, playerImg.width * SCALE, playerImg.height * SCALE);
  }

  float getRadius() {
    return max(playerImg.width, playerImg.height) * SCALE * 0.25;
  }
}

// === Bullet ===
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

// === Explosion ===
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
    imageMode(CENTER);
    image(img, x, y, img.width * SCALE, img.height * SCALE);
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
    super(x, y, 2, basicEnemyImg);
  }

  void update() {
    y += 2 * 0.75;
  }

  void shoot() {
    // no shooting
  }
}

// === Advanced Enemy ===
class AdvancedEnemy extends Enemy {
  int shootTimer = 0;

  AdvancedEnemy(float x, float y) {
    super(x, y, 4, advancedEnemyImg);
    float dx = player.x - x;
    float dy = player.y - y;
    float mag = sqrt(dx * dx + dy * dy);
    vx = dx / mag * 1.5 * 0.75;
    vy = dy / mag * 1.5 * 0.75;
  }

  void update() {
    x += vx;
    y += vy;
    shootTimer++;
  }

  void shoot() {
    if (y > 400) return;
    if (shootTimer > 100) {
      float dx = player.x - x;
      float dy = player.y - y;
      float mag = sqrt(dx * dx + dy * dy);
      dx = dx / mag * 3;
      dy = dy / mag * 3;
      bullets.add(new Bullet(x, y, dx, dy, advEnemyBulletImg, this));
      shootTimer = 0;
    }
  }
}

// === Very Advanced Enemy ===
class VeryAdvancedEnemy extends Enemy {
  int shootTimer = 0;

  VeryAdvancedEnemy(float x, float y) {
    super(x, y, 6, veryAdvancedEnemyImg);
    float dx = player.x - x;
    float dy = player.y - y;
    float mag = sqrt(dx * dx + dy * dy);
    vx = dx / mag * 1.8 * 0.75;
    vy = dy / mag * 1.8 * 0.75;
  }

  void update() {
    x += vx;
    y += vy;
    shootTimer++;
  }

  void shoot() {
    if (y > 400) return;
    if (shootTimer > 110) {
      float angle = atan2(player.y - y, player.x - x);
      float speed = 3.3;
      float offset = PI / 12;
      bullets.add(new Bullet(x, y, speed * cos(angle - offset), speed * sin(angle - offset), veryAdvEnemyBulletImg, this));
      bullets.add(new Bullet(x, y, speed * cos(angle + offset), speed * sin(angle + offset), veryAdvEnemyBulletImg, this));
      shootTimer = 0;
    }
  }
}
