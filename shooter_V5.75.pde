import processing.sound.*;

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
float displayedLives = 6;
int maxLives = 6;
int score = 0;
boolean gameOver = false;
boolean gameStarted = false;
boolean paused = false;
boolean upgradeMenu = false;
boolean enableKeyPress = false;
PFont font;
int specialAbilityBullets = 170;

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

// === Firing ===
float energy = 100;
float displayedEnergy = 100;
float barSmoothingSpeed = 0.2; // smaller = smoother transition
float maxEnergy = 100;
float energyRegenRate = 30;
float originalEnergyRegenRate = 30;
float energyCostPerShot = 10;
boolean firing = false;
boolean outOfEnergy = false;
boolean onCooldown = false;

// === Button Dimensions & Positions ===
float buttonWidth = 200;
float buttonHeight = 20;
float startBtnX, startBtnY;
float restartBtnX, restartBtnY;

// === Laser Settings ===
int laserDamage = 0;

// === Magnet Settings ===
float magnetRadius = 0;
float magnetSpeed  = 6.0;

// === Sound Effects ===
SoundFile sfxPlayerShoot;
SoundFile sfxEnemyShoot;
SoundFile sfxEnemyDie;
SoundFile sfxSpecial;

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
  
  // Load sound effects
  sfxPlayerShoot = new SoundFile(this, "player_shoot.wav");
  sfxEnemyShoot = new SoundFile(this, "enemy_shoot.wav");
  sfxEnemyDie = new SoundFile(this, "enemy_die.mp3");
  sfxSpecial = new SoundFile(this, "special_1.wav");
  sfxEnemyDie.amp(2.0);
  sfxSpecial.amp(2.0);
  sfxPlayerShoot.amp(0.5);
  sfxEnemyShoot.amp(0.1);
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
    startBtnX = width / 2;
    startBtnY = height / 2 + 20;
    drawButton(startBtnX, startBtnY, 200, 20, "START");
    drawButton(startBtnX, startBtnY + 30, 150, 20, "CREDITS");
    drawButton(startBtnX, startBtnY + 60, 150, 20, "QUIT");
    //text("Press ENTER to Start", width / 2, height / 2 + 20);
    return;
  }

  if (upgradeMenu) {
    fill(255, 255, 0);
    textAlign(CENTER, CENTER);
    textSize(24);
    text("Collectable Goal Reached!", width / 2, height / 2 - 60);
    text("Press 1 to increase Max Health", width / 2, height / 2 - 20);
    text("Press 2 to increase Bullet Count", width / 2, height / 2 + 20);
    text("Press 3 to increase Energy Recharge", width / 2, height / 2 + 60);
    text("Press 4 to improve Special Ability", width / 2, height / 2 + 100);
    text("Press 5 to increase Laser Strength", width / 2, height / 2 + 140);
    text("Press 6 to increase Magnet Pull", width / 2, height / 2 + 180);
    return;
  }

  if (paused) {
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(36);
    text("GAME PAUSED", width / 2, height / 2);
    return;
  }
  
  if (onCooldown)
    energy = constrain(energy + (energyRegenRate + ((originalEnergyRegenRate - energyRegenRate)/2.5)) * (1.0 / frameRate), 0, maxEnergy);
  else
    energy = constrain(energy + energyRegenRate * (1.0 / frameRate), 0, maxEnergy);
  
  displayedEnergy += (energy - displayedEnergy) * barSmoothingSpeed;
  displayedLives += (lives - displayedLives) * barSmoothingSpeed;
  
  if (onCooldown)
    if (energy == maxEnergy)
      onCooldown = false;

  if (gameOver) {
    fill(255, 0, 0);
    textAlign(CENTER, CENTER);
    textSize(36);
    text("GAME OVER", width / 2, height / 2 - 30);
    textSize(24);
    fill(255);
    text("Final Score: " + score, width / 2, height / 2 + 13);
    
    restartBtnX = width / 2;
    restartBtnY = height / 2 + 50;
    drawButton(restartBtnX, restartBtnY, 200, 20, "RESPAWN");
    drawButton(restartBtnX, restartBtnY + 30, 150, 20, "MENU");
    //text("Press R to Respawn", width / 2, height / 2 + 50);
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
          sfxEnemyDie.play();
          explosions.add(new Explosion(e.x, e.y));
          if (e instanceof BasicEnemy) {
            score += 1;
            if (random(1) < 1.0 / 6) collectables.add(new Collectable(e.x, e.y));
          } else if (e instanceof AdvancedEnemy) {
            score += 5;
            if (random(1) < 1) collectables.add(new Collectable(e.x, e.y));
          } else if (e instanceof VeryAdvancedEnemy) {
            score += 10;
            collectables.add(new BigCollectable(e.x, e.y));
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

    // ——— Magnet Pull ——
    float d = dist(c.x, c.y, player.x, player.y);
    if (magnetRadius > 0 && d < magnetRadius) {
      // Compute a unit vector from collectable to player
      float dx = player.x - c.x;
      float dy = player.y - c.y;
      float mag = sqrt(dx*dx + dy*dy);
      if (mag != 0) {
        dx /= mag;
        dy /= mag;
      }
      // Move collectable toward player at magnetSpeed
      c.x += dx * magnetSpeed;
      c.y += dy * magnetSpeed;

      // Still rotate it (copying what update() did)
      c.rotation += c.rotationSpeed;
    } 
    else {
      // Normal falling + rotation
      c.update();
    }

    c.display();

    if (dist(c.x, c.y, player.x, player.y) < player.getRadius()) {
      collectables.remove(i);
      if (c.returnType().equals("basic")) {
        collectableCount++;
      } 
      else if (c.returnType().equals("big")) {
        collectableCount += 2;
      }

      if (collectableCount >= collectableGoal) {
        upgradeMenu = true;
        paused = true;
      }
    } 
    else if (c.y > height + 20) {
      // off‐screen, remove
      collectables.remove(i);
    }
  }


  // —————— Laser Beam Rendering & Damage ——————
if (laserDamage > 0) {
  // 1) Pulsing beam thickness:
  float pulseFactor   = 1 + 0.3 * sin(radians(frameCount * 5));
  float beamWidth     = laserDamage * pulseFactor;
  float beamCoreWidth = max(2, beamWidth * 0.3);
  float halfBeam      = beamWidth / 2.0;

  // 2) Find the blocker enemy:
  //    We want the enemy whose CIRCLE (radius = e.getRadius()) intersects the vertical
  //    band [player.x - halfBeam, player.x + halfBeam], and that is closest (largest e.y + radius).
  Enemy blocker    = null;
  float blockerY   = -1;
  for (Enemy e : enemies) {
    // Only consider enemies above the player:
    if (e.y < player.y) {
      float dx = abs(e.x - player.x);
      if (dx < halfBeam + e.getRadius()) {
        // Compute bottom‐most point of the enemy circle:
        float bottomY = e.y + e.getRadius();
        if (bottomY > blockerY) {
          blocker  = e;
          blockerY = bottomY;
        }
      }
    }
  }

  // 3) Compute beam endpoints (beamBottom is just above player, beamTop is at blocker or top of screen):
  float beamBottom = player.y - player.getRadius();
  float beamTop    = (blocker != null) ? blockerY : 0;

  // 4) Draw red outer glow (semi‐transparent) from beamBottom up to beamTop
  stroke(255, 0, 0, 180);
  strokeWeight(beamWidth);
  line(player.x, beamBottom, player.x, beamTop);

  // 5) Draw white inner core
  stroke(255, 255, 255, 220);
  strokeWeight(beamCoreWidth);
  line(player.x, beamBottom, player.x, beamTop);

  noStroke();

  // 6) Damage only that blocker (if it exists)
  if (blocker != null) {
    blocker.hp -= laserDamage / (frameRate * 1.5);
    if (blocker.hp <= 0) {
      explosions.add(new Explosion(blocker.x, blocker.y));

      // Award points & drop collectable per your existing logic:
      if (blocker instanceof BasicEnemy) {
        score += 1;
        if (random(1) < 1.0/6) {
          collectables.add(new Collectable(blocker.x, blocker.y));
        }
      } else if (blocker instanceof AdvancedEnemy) {
        score += 5;
        collectables.add(new Collectable(blocker.x, blocker.y));
      } else if (blocker instanceof VeryAdvancedEnemy) {
        score += 10;
        collectables.add(new BigCollectable(blocker.x, blocker.y));
      }

      // Remove that enemy from the list
      enemies.remove(blocker);
    }
  }
}



  // Draw HUD
  drawHealthBar();
  drawEnergyBar();
  fill(255);
  textAlign(LEFT, TOP);
  textSize(20);
  text("Score: " + score, 10, 35);
  text("Collectables: " + collectableCount + "/" + collectableGoal, 10, 60);
}

  boolean isMouseOver(float cx, float cy, float w, float h) {
    return mouseX > cx - w / 2 && mouseX < cx + w / 2 &&
           mouseY > cy - h / 2 && mouseY < cy + h / 2;
  }

  void drawButton(float cx, float cy, float w, float h, String label) {
    rectMode(CENTER);
    
    boolean hovered = isMouseOver(cx, cy, w, h);
    boolean pressed = hovered && mousePressed;
  
    // Background color
    if (pressed) {
      fill(80, 180, 255);  // Pressed color
    } else if (hovered) {
      fill(100, 200, 255); // Hover color
    } else {
      fill(50, 150);       // Normal
    }
  
    stroke(255);
    strokeWeight(1.5);
    rect(cx, cy, w, h, 10);
  
    // Text
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(18);
    text(label, cx, cy);
  
    rectMode(CORNER);
  }


void mousePressed() {
  if (!gameStarted) {
    // Check if click is within Start button
    if (mouseX > startBtnX - buttonWidth/2 && mouseX < startBtnX + buttonWidth/2 &&
        mouseY > startBtnY - buttonHeight/2 && mouseY < startBtnY + buttonHeight/2) {
      gameStarted = true;
    }
  } else if (gameOver) {
    // Check if click is within Restart button
    if (mouseX > restartBtnX - buttonWidth/2 && mouseX < restartBtnX + buttonWidth/2 &&
        mouseY > restartBtnY - buttonHeight/2 && mouseY < restartBtnY + buttonHeight/2) {
      // Reset game state
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
    }
  }
}

void drawEnergyBar() {
  int barWidth = 180;
  int barHeight = 8;
  int x = 10;
  int y = 22;  // Below the health bar

  float energyRatio = constrain(displayedEnergy / maxEnergy, 0, 1);

  // Background
  noStroke();
  fill(30);
  rect(x, y, barWidth, barHeight, 10);

  // Energy fill (blue)
  if (onCooldown)
    fill(255, 100, 0);
  else
    fill(0, 150, 255);
  rect(x, y, barWidth * energyRatio, barHeight, 10);

  // Outline
  noFill();
  stroke(255);
  strokeWeight(1);
  rect(x, y, barWidth, barHeight, 10);
}


void drawHealthBar() {
  int barWidth = 180;
  int barHeight = 8;
  int x = 10;
  int y = 10;
  
  float healthRatio = constrain(displayedLives / maxLives, 0, 1);

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

  if (!gameStarted && key == ENTER && enableKeyPress) {
    gameStarted = true;
    return;
  }

  if (gameOver && (key == 'r' || key == 'R') && enableKeyPress) {
    clearInput();
    gameOver = false;
    lives = maxLives;
    laserDamage = 0;
    magnetRadius = 0;
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
  
  if (key == 'x' || key == 'X') {
    if (energy >= maxEnergy) {
      float angleStep = TWO_PI / specialAbilityBullets;
      for (int i = 0; i < specialAbilityBullets; i++) {
        float angle = i * angleStep;
        float speed = 5;
        float dx = cos(angle) * speed;
        float dy = sin(angle) * speed;
        bullets.add(new Bullet(player.x, player.y, dx, dy, playerBulletImg, player));
      }
      sfxSpecial.play();
      energy = 0;
    }
  }


  if (upgradeMenu) {
    if (key == '1') {
      maxLives += 1;
      lives = maxLives;
    } else if (key == '2') {
      shotgunCount++;
    } else if (key == '3') {
      energyRegenRate += 6;
    } else if (key == '4') {
      specialAbilityBullets += 50;
    } else if (key == '5') {
      laserDamage += 5;
    } else if (key == '6') {
      magnetRadius += 75;
    }else {
      return;
    }
    clearInput();
    collectableCount = 0;
    collectableGoal += 2;
    enemySpawnCount = max(20, enemySpawnCount - 5);
    upgradeMenu = false;
    paused = false;
    return;
  }

  if (paused || !gameStarted || gameOver) return;

  // === Handle Continuous Firing with Energy ===
  if (keyPressed && key == ' ' && energy >= energyCostPerShot && !onCooldown) {
    sfxPlayerShoot.play();
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
  
    energy -= energyCostPerShot;
  }
  else if (energy < energyCostPerShot)
    onCooldown = true;


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
  float angle;

  Bullet(float x, float y, float vx, float vy, PImage img) {
    this(x, y, vx, vy, img, null);
    this.angle = atan2(vy, vx);
  }

  Bullet(float x, float y, float vx, float vy, PImage img, Object source) {
    this.x = x;
    this.y = y;
    this.vx = vx;
    this.vy = vy;
    this.img = img;
    this.source = source;
    this.angle = atan2(vy, vx);
  }

  void update() {
    x += vx;
    y += vy;
  }

  void display() {
    pushMatrix();
    translate(x, y);
    rotate(angle + HALF_PI); // Rotate bullet image by 90°
    imageMode(CENTER);
    image(img, 0, 0);
    popMatrix();
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

  void display(float size) {
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
  
  String returnType() {
    return "basic";
  }
}

// === Big Collectable Class ===
class BigCollectable extends Collectable {
  float x, y;
  float vy = 2;
  float size = 26;         // Size of the lemon and its hitbox
  float rotation = 0;      // Current rotation angle in radians
  float rotationSpeed = 5;     // How fast it spins

  BigCollectable(float x, float y) {
    super(x,y);
  }
  
  void display() {
    super.display(size);
  }
  
  String returnType() {
    return "big";
  }
}

// === Enemy Base Class ===
abstract class Enemy {
  float x, y;
  float hp;
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
      sfxEnemyShoot.play();
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
      sfxEnemyShoot.play();
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
