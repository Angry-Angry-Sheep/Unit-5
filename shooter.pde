// === Asset Images ===
PImage playerImg, basicEnemyImg, advancedEnemyImg, veryAdvancedEnemyImg;
PImage playerBulletImg, advEnemyBulletImg, veryAdvEnemyBulletImg;

// === Game Objects ===
ArrayList<Bullet> bullets = new ArrayList<Bullet>();
ArrayList<Enemy> enemies = new ArrayList<Enemy>();
Player player;

// === Constants ===
final float SCALE = 3;

void setup() {
  size(800, 600);
  frameRate(60);

  playerImg = loadImage("Player.bmp");
  basicEnemyImg = loadImage("Basic Enemy.bmp");
  advancedEnemyImg = loadImage("Advanced Enemy.bmp");
  veryAdvancedEnemyImg = loadImage("Very Advanced Enemy.bmp");
  playerBulletImg = loadImage("Bullet.bmp");
  advEnemyBulletImg = loadImage("advanced_enemy_bullet.bmp");
  veryAdvEnemyBulletImg = loadImage("very_advanced_enemy_bullet.bmp");

  player = new Player(width/2, height - 100);
}

void draw() {
  background(0);

  player.update();
  player.display();

  for (int i = bullets.size()-1; i >= 0; i--) {
    Bullet b = bullets.get(i);
    b.update();
    b.display();
    if (b.isOffscreen()) bullets.remove(i);
  }

  if (frameCount % 60 == 0) spawnEnemies();

  for (int i = enemies.size()-1; i >= 0; i--) {
    Enemy e = enemies.get(i);
    e.update();
    e.display();
    e.shoot();

    if (e.checkCollision(player)) {
      println("Player hit!");
      // Handle player damage
    }

    for (int j = bullets.size()-1; j >= 0; j--) {
      Bullet b = bullets.get(j);
      if (e.checkBulletHit(b)) {
        e.hp--;
        bullets.remove(j);
        if (e.hp <= 0) {
          enemies.remove(i);
          break;
        }
      }
    }
  }
}

void keyPressed() {
  if (key == ' ') {
    bullets.add(new Bullet(player.x, player.y - 20, 0, -5, playerBulletImg, player));
  }
  if (key == 'a' && player.vx > 0) player.vx = -player.vx;
  if (key == 'd' && player.vx < 0) player.vx = -player.vx;
}

void spawnEnemies() {
  float x = random(50, width - 50);
  int type = int(random(0, 3));
  if (type == 0) enemies.add(new BasicEnemy(x, -40));
  if (type == 1) enemies.add(new AdvancedEnemy(x, -40));
  if (type == 2) enemies.add(new VeryAdvancedEnemy(x, -40));
}

// === Player ===
class Player {
  float x, y;
  float vx = 5;

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

  boolean checkCollision(Player p) {
    return dist(x, y, p.x, p.y) < 30;
  }

  boolean checkBulletHit(Bullet b) {
    if (b.source == this) return false;
    return dist(x, y, b.x, b.y) < 25;
  }
}

// === Basic Enemy ===
class BasicEnemy extends Enemy {
  BasicEnemy(float x, float y) {
    super(x, y, 2, basicEnemyImg);
  }

  void update() {
    y += 2;
  }

  void shoot() {}
}

// === Advanced Enemy ===
class AdvancedEnemy extends Enemy {
  int shootTimer = 0;

  AdvancedEnemy(float x, float y) {
    super(x, y, 4, advancedEnemyImg);
    float dx = player.x - x;
    float dy = player.y - y;
    float mag = sqrt(dx * dx + dy * dy);
    vx = dx / mag * 1.5;
    vy = dy / mag * 1.5;
  }

  void update() {
    x += vx;
    y += vy;
    shootTimer++;
  }

  void shoot() {
    if (shootTimer > 120) {
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
    super(x, y, 5, veryAdvancedEnemyImg);
    float dx = player.x - x;
    float dy = player.y - y;
    float mag = sqrt(dx * dx + dy * dy);
    vx = dx / mag * 1.8;
    vy = dy / mag * 1.8;
  }

  void update() {
    x += vx;
    y += vy;
    shootTimer++;
  }

  void shoot() {
    if (shootTimer > 100) {
      float angle = atan2(player.y - y, player.x - x);
      float speed = 3;
      float offset = PI / 12;
      bullets.add(new Bullet(x, y, speed * cos(angle - offset), speed * sin(angle - offset), veryAdvEnemyBulletImg, this));
      bullets.add(new Bullet(x, y, speed * cos(angle + offset), speed * sin(angle + offset), veryAdvEnemyBulletImg, this));
      shootTimer = 0;
    }
  }
}
