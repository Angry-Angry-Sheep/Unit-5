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
ArrayList<BossLaser> bossLasers = new ArrayList<BossLaser>();
ArrayList<Star> stars = new ArrayList<Star>();
Player player;

// === Boss ===
Boss boss = null;
boolean bossDefeated = false;


// === Abilities ===
boolean pulseAbility = false;
boolean magnetAbility = false;
boolean laserAbility = false;
int healthCost = 15;

// === Constants ===
final float SCALE = 2.5;
int shotgunCount = 1;
int enemySpawnCount = 100;
int playerSpeed = 5;

// === Game State ===
int lives = 3;
float displayedLives = 4;
int maxLives = 4;
int score = 0;
boolean gameOver = false;
boolean gameStarted = false;
boolean paused = false;
boolean upgradeMenu = false;
boolean enableKeyPress = false;
boolean clickConsumed = false;
PFont font;
int specialAbilityBullets = 100;

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
int money = 100000;
boolean inStore = false;

// === Firing ===
float energy = 100;
float displayedEnergy = 100;
float barSmoothingSpeed = 0.2; // smaller -> smoother transition
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
SoundFile BOSS_MUSIC;

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

  player = new Player(width / 2, height - 100, playerSpeed);

  // Initialize space background
  for (int i = 0; i < 150; i++) {
    stars.add(new Star());
  }
  
  // Load sound effects
  sfxPlayerShoot = new SoundFile(this, "player_shoot.wav");
  sfxEnemyShoot = new SoundFile(this, "enemy_shoot.wav");
  sfxEnemyDie = new SoundFile(this, "enemy_die.mp3");
  sfxSpecial = new SoundFile(this, "special_1.wav");
  BOSS_MUSIC = new SoundFile(this, "JoJo's Bizarre Adventure OST - Pillar Men ThemeAwaken.mp3");
  sfxEnemyDie.amp(1.0);
  sfxSpecial.amp(1.0);
  sfxPlayerShoot.amp(0.5);
  sfxEnemyShoot.amp(0.1);
}

void draw() {
  drawSpaceBackground();
  
  if (bossDefeated) {
    // imporved Victory Screen
  if (!victoryInit) {
    for (int i = 0; i < 200; i++) confetti.add(new Confetti());
    victoryInit = true;
  }
  background(0, 180);
  
  for (int i = confetti.size()-1; i >= 0; i--) {
    Confetti c = confetti.get(i);
    c.update();
    c.display();
    if (c.y > height + 20) confetti.remove(i);
  }
  
  float pulse = 1 + 0.05f * sin(radians(frameCount * 4));
  textAlign(CENTER, CENTER);
  textSize(64 * pulse);
  // drop-shadow
  fill(0, 150);
  text("VICTORY!", width/2 + 4, height/2 - 24 + 4);
  // main text
  fill(255, 215, 0);
  text("VICTORY!", width/2, height/2 - 24);
  
  float bounce = abs(sin(radians(frameCount * 2))) * 10;
  textSize(24);
  fill(255);
  text("You beat the game!!", width/2, height/2 + 30 + bounce);
  
  return;
}

 
  if (!gameStarted && !inStore) {
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
    drawButton(startBtnX, startBtnY + 30, 150, 20, "STORE");
    drawButton(startBtnX, startBtnY + 60, 150, 20, "QUIT");
    return;
  }
  else if (inStore) {
    // Back to main menu
    if (isMouseOver(width/2, 400, 180, 30) && mousePressed && !clickConsumed) {
      clickConsumed = true;
      inStore = false;
      return;
    }
    // Buy Extra Life
    if (isMouseOver(width/2, 200, 180, 30) && money >= healthCost && mousePressed && !clickConsumed) {
      clickConsumed = true;
      money -= healthCost;
      healthCost = healthCost * 2;
      maxLives++;
      lives = maxLives;
    }
    // Get Pulse Ability
    if (isMouseOver(width/2, 240, 180, 30) && money >= 100 && mousePressed && !clickConsumed && !pulseAbility) {
      money -= 100;
      clickConsumed = true;
      pulseAbility = true;
    }
    // Get Magnet Ability
    if (isMouseOver(width/2, 280, 180, 30) && money >= 50 && mousePressed && !clickConsumed && !magnetAbility) {
      money -= 50;
      clickConsumed = true;
      magnetAbility = true;
    }
    // Get Laser Module
    if (isMouseOver(width/2, 320, 180, 30) && money >= 500 && mousePressed && !clickConsumed && !laserAbility) {
      money -= 500;
      clickConsumed = true;
      laserAbility = true;
    }
    // Get More Speed
    if (isMouseOver(width/2, 360, 180, 30) && money >= 25 && mousePressed && !clickConsumed && playerSpeed <= 8) {
      money -= 25;
      playerSpeed += 1; 
      clickConsumed = true;
    }
  }

  if (inStore) {
    background(20);
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(36);
    text("== STORE ==", width/2, 80);
    textSize(24);
    text("Money: $" + money, width/2, 130);
    drawButton(width/2, 200, 180, 30, "Extra Life ($" + healthCost+ ")");
    drawButton(width/2, 240, 180, 30, "Pulse Power ($100)", pulseAbility);
    drawButton(width/2, 280, 180, 30, "Magnet Module ($50)", magnetAbility);
    drawButton(width/2, 320, 180, 30, "Laser Module ($500)", laserAbility);
    drawButton(width/2, 360, 180, 30, "Extra Speed ($25)", (playerSpeed > 8));
    drawButton(width/2, 400, 180, 30, "Back to Menu");
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
    if (pulseAbility)
      text("Press 4 to improve Special Ability", width / 2, height / 2 + 100);
    else
      drawStrikethroughText("Press 4 to improve Special Ability", width / 2, height / 2 + 100);
    if (laserAbility)
      text("Press 5 to increase Laser Strength", width / 2, height / 2 + 140);
    else
      drawStrikethroughText("Press 5 to increase Laser Strength", width / 2, height / 2 + 140);
    if (magnetAbility)
      text("Press 6 to increase Magnet Pull", width / 2, height / 2 + 180);
    else
      drawStrikethroughText("Press 6 to increase Magnet Pull", width / 2, height / 2 + 180);
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
  
  if (boss == null && frameCount % enemySpawnCount == 0) {
    spawnEnemies();
  }
  
  // update & display all active lasers
  for (int i = bossLasers.size()-1; i >= 0; i--) {
    BossLaser L = bossLasers.get(i);
    L.update();
    L.display();
    if (L.finished()) bossLasers.remove(i);
  }

  
// --- Boss spawn & handling ---
if (score >= 1 && boss == null) {
  boss = new Boss(width/2, 200);
  // wipe out current enemies
  for (Enemy e : enemies) {
    explosions.add(new Explosion(e.x, e.y));
  }
  enemies.clear();
}

if (boss != null) {
  boss.update();
  boss.shoot();
  
  for (int i = bullets.size()-1; i >= 0; i--) {
    Bullet b = bullets.get(i);
    if (b.source instanceof Player &&
        dist(b.x, b.y, boss.x, boss.y) < boss.getRadius()) {
      boss.hp -= 10;
      bullets.remove(i);
      if (boss.hp <= 0) {
        float bx = boss.x;
        float by = boss.y;
        
        // big explosion ring
        for (int k = 0; k < 20; k++) {
          // small explosions
          float ex = bx + random(-50, 50);
          float ey = by + random(-50, 50);
          explosions.add(new Explosion(ex, ey));
        }
        bossDefeated = true;
        break;
      }
    }
  }

  if (boss != null) {
    boss.display();
  }
}


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
      c.x += dx * magnetSpeed;
      c.y += dy * magnetSpeed;

      c.rotation += c.rotationSpeed;
    } 
    else {
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
  // thickness
  float pulseFactor   = 1 + 0.3 * sin(radians(frameCount * 5));
  float beamWidth     = laserDamage * pulseFactor;
  float beamCoreWidth = max(2, beamWidth * 0.3);
  float halfBeam      = beamWidth / 2.0;

  // find target
  Enemy blocker = null;
  float blockerY = -1;
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

  // beam endpoints
  float beamBottom = player.y - player.getRadius();
  float beamTop = (blocker != null) ? blockerY : 0;

  // red outer glow
  stroke(255, 0, 0, 180);
  strokeWeight(beamWidth);
  line(player.x, beamBottom, player.x, beamTop);

  // Draw white inner core
  stroke(255, 255, 255, 220);
  strokeWeight(beamCoreWidth);
  line(player.x, beamBottom, player.x, beamTop);

  noStroke();

  // damage only that blocker
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

      // remove target
      enemies.remove(blocker);
    }
  }
}



  // HUD
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
      fill(80, 180, 255); // Pressed color
    } else if (hovered) {
      fill(100, 200, 255); // Hover color
    } else {
      fill(50, 150); // Normal
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

  void drawButton(float cx, float cy, float w, float h, String label, boolean disabled) {
    rectMode(CENTER);
    
    boolean hovered = isMouseOver(cx, cy, w, h);
    boolean pressed = hovered && mousePressed;
  
    // Background color
    if (pressed) {
      fill(80, 180, 255); // Pressed color
    } else if (hovered) {
      fill(100, 200, 255); // Hover color
    } else {
      fill(50, 150); // Normal
    }
  
    stroke(255);
    strokeWeight(1.5);
    rect(cx, cy, w, h, 10);
  
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(18);
    if (disabled)
      fill(255, 0, 0);
    text(label, cx, cy);
      
  
    rectMode(CORNER);
  }
  
void drawStrikethroughText(String txt, float x, float y) {
  fill(255,0,0);
  noStroke();
  text(txt, x, y);
  
  float w = textWidth(txt);
  float lineY = y;
  
  stroke(255);
  strokeWeight(2);
  line(x - x/2 + w/10, lineY, x + w - x/2, lineY);
}

void mouseReleased() {
  clickConsumed = false;
}

void mousePressed() {
  if (clickConsumed) return;  
  
  if (!gameStarted && !inStore) {
    // START button
    if (mouseX > startBtnX - buttonWidth/2 && mouseX < startBtnX + buttonWidth/2 &&
        mouseY > startBtnY - buttonHeight/2 && mouseY < startBtnY + buttonHeight/2) {
      gameStarted = true;
      
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
      laserDamage = 0;
      magnetRadius = 0;
      player = new Player(width / 2, height - 100, playerSpeed);
      return;
      //'''
    }

    // QUIT button
    float quitBtnY = startBtnY + 60;
    float quitBtnW = 150;
    if (mouseX > startBtnX - quitBtnW/2 && mouseX < startBtnX + quitBtnW/2 &&
        mouseY > quitBtnY - buttonHeight/2 && mouseY < quitBtnY + buttonHeight/2 && !inStore) {
      exit();  // close the Processing sketch
    }
    
    // STORE BUTTON
    if (isMouseOver(startBtnX, startBtnY+30, 150, 20)) {
      inStore = true;
      clickConsumed = true;   
      return;
    }
  } 
  else if (gameOver) {
    if (lives <= 0) {
      money += score;
      score = 0;
    }
    // RESPAWN button
    if (mouseX > restartBtnX - buttonWidth/2 && mouseX < restartBtnX + buttonWidth/2 &&
        mouseY > restartBtnY - buttonHeight/2 && mouseY < restartBtnY + buttonHeight/2) {
      // Reset game to play again
      clearInput();
      gameOver = false;
      lives = maxLives;
      bullets.clear();
      enemies.clear();
      explosions.clear();
      collectables.clear();
      if (boss != null) {
        boss = null;
        BOSS_MUSIC.stop();
        boss = new Boss(width/2, 200);
      }
      else {
        collectableCount = 0;
        collectableGoal = 4;
        shotgunCount = 1;
        enemySpawnCount = 80;
        laserDamage = 0;
        magnetRadius = 0;
      }
      player = new Player(width / 2, height - 100, playerSpeed);
      clickConsumed = true;   
      return;
    }

    float menuBtnY = restartBtnY + 30;
    float menuBtnW = 150;
    if (mouseX > restartBtnX - menuBtnW/2 && mouseX < restartBtnX + menuBtnW/2 &&
        mouseY > menuBtnY - buttonHeight/2 && mouseY < menuBtnY + buttonHeight/2) {
      boss = null;
      BOSS_MUSIC.stop();
      gameStarted = false;
      clickConsumed = true;   
      clearInput();
      return;
    }
  }
}


void drawEnergyBar() {
  int barWidth = 180;
  int barHeight = 8;
  int x = 10;
  int y = 22;  // Below the health bar

  float energyRatio = constrain(displayedEnergy / maxEnergy, 0, 1);

  noStroke();
  fill(30);
  rect(x, y, barWidth, barHeight, 10);

  if (onCooldown)
    fill(255, 100, 0);
  else
    fill(0, 150, 255);
  rect(x, y, barWidth * energyRatio, barHeight, 10);

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

  noStroke();
  fill(60);
  rect(x, y, barWidth, barHeight, 10);

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
    player = new Player(width / 2, height - 100, playerSpeed);
    return;
  }
  
  if ((key == 'x' || key == 'X') && pulseAbility) {
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
    } else if (key == '4' && pulseAbility) {
      specialAbilityBullets += 50;
    } else if (key == '5' && laserAbility) {
      laserDamage += 5;
    } else if (key == '6' && magnetAbility) {
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

  Player(float x, float y, float speed) {
    this.x = x;
    this.y = y;
    this.speed = speed;
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
    rotate(angle + HALF_PI);
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
  float size = 20;         
  float rotation = 0;  
  float rotationSpeed = 5;

  Collectable(float x, float y) {
    this.x = x;
    this.y = y;
    this.rotationSpeed = random(-0.1, 0.1);
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
  float size = 26;
  float rotation = 0;
  float rotationSpeed = 5;

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
    float angle = atan2(vy, vx);
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

class Boss extends Enemy {
  // movement/dodge
  float maxSpeed = 4;
  float dodgeForce = 750;
  float dodgeRadius = 120;

  // bullet spawn radius
  float spawnRadius = 60;

  // attack cycles
  int patternIndex = 0;
  int patternTimer = 0;
  int patternDuration = 8 * 60;
  float patternAngle = 0;

  // health and display smoothing
  float maxHp;
  float displayedHp;
  float hpSmoothing = 0.05;

  // intro scene
  float startY;
  float startX;
  float introScale = 2.0;
  float flashAlpha = 255;

  // text flash
  boolean justSpawned = false;
  int postFlashTimer = 0;
  int postFlashDur = 1 * 60;

  boolean introActive = true;
  int introTimer = 0;
  int introDuration = 200;

  // second flash on actual spawn
  boolean spawnFlashActive = false;
  int spawnFlashTimer = 0;
  int spawnFlashDur = 60;
  
  boolean phase2 = false;
  float auraPhase = 0;


  Boss(float x, float y) {
    super(x, -200, 200, veryAdvancedEnemyImg);
    this.startX = x;
    this.startY = y;
    this.hp = 100;
    this.maxHp = this.hp;
    this.displayedHp = this.hp;
    this.img = loadImage("Boss.bmp");
    vx = vy = 0;
    BOSS_MUSIC.play();
  }

  @Override
  void update() {
    displayedHp += (hp - displayedHp) * hpSmoothing;
    
    if (!introActive && !phase2 && hp <= maxHp/2) {
      phase2 = true;
      patternIndex = 4;
      patternTimer = 0;
      maxSpeed *= 1.3;
    }

    if (introActive) {
      introTimer++;
      hp = maxHp;
      float t = constrain(introTimer / (float)introDuration, 0, 1);
      y = lerp(-200, startY, 1 - sq(1 - t));
      introScale = lerp(2.0, 1.3, t);
      flashAlpha = lerp(255, 0, t);
      if (introTimer >= introDuration) {
        introActive      = false;
        spawnFlashActive = true;
        spawnFlashTimer  = 0;
        float a = random(TWO_PI);
        vx = cos(a) * maxSpeed;
        vy = sin(a) * maxSpeed * 0.5;
      }
      return;
    }

    if (bossDefeated) {
      enemies.remove(this);
      enemies.clear();
      BOSS_MUSIC.stop();
      return;
    }

    x += vx;  y += vy;
    float bounceStrength = 5;
    if (x < 50) {
      x = 50;
      vx = abs(vx) * bounceStrength;
    }
    if (x > width - 50) {
      x = width - 50;
      vx = -abs(vx) * bounceStrength;
    }
    if (y < 50) {
      y = 50;
      vy = abs(vy) * bounceStrength;
    }
    if (y > height / 2) {
      y = height / 2;
      vy = -abs(vy) * bounceStrength;
    }


    for (Bullet b : bullets) {
      if (!(b.source instanceof Player)) continue;
      float dx = x - b.x, dy = y - b.y;
      float d2 = dx*dx + dy*dy;
      if (d2 < dodgeRadius*dodgeRadius && d2 > 0) {
        float d = sqrt(d2), ux = dx/d, uy = dy/d;
        float imp = dodgeForce / (d + 10);
        vx += ux * imp * (1/frameRate);
        vy += uy * imp * (1/frameRate);
      }
    }
    float spd = sqrt(vx * vx + vy * vy);
    if (spd > maxSpeed) { vx = vx/spd * maxSpeed; vy = vy/spd * maxSpeed; }
    if (phase2) {
      auraPhase += TWO_PI * (1.0/60);  // one cycle per second
    }
  }

  @Override
  void shoot() {
    if (introActive || bossDefeated) return;
    patternTimer++;
    int dur = (patternIndex == 1) ? 3 * 60 : patternDuration;
    if (patternTimer >= dur) {
      patternTimer = 0;
      patternIndex = (patternIndex + 1) % 4;
    }
    switch(patternIndex) {
      case 0:
        if (patternTimer % (2*60) == 0)
          for (int i = 0; i < 24; i++)
            spawnBullet(TWO_PI*i/24, 4, 1);
        break;
      case 1:
        patternAngle += radians(20);
        spawnBullet(patternAngle, 5, 1);
        break;
      case 2:
        if (patternTimer % 90 == 0) {
          float base = atan2(player.y - y, player.x - x);
          for (int i = 0; i < 5; i++) {
            float spr = PI/8;
            float a = base - spr/2 + spr * i/4;
            spawnBullet(a, 10, 2);
          }
        }
        break;
      case 3:
        patternAngle += radians(2.5);
        if (patternTimer % (0.1*60) == 0) {
          spawnBullet(patternAngle, 8, 1);
          spawnBullet(patternAngle + PI, 8, 2);
          spawnBullet(patternAngle - HALF_PI, 8, 1);
          spawnBullet(patternAngle + HALF_PI, 8, 2);
        }
        break;
        
      case 4:
      if (phase2 && patternTimer % 60 == 0) {
        for (int i = 0; i < 4; i++) {
          bullets.add(new HomingBullet(x, y, player, veryAdvEnemyBulletImg, this));
        }
      }
      break;

    case 5:
      if (phase2 && patternTimer == 1) {
        // fire a 2-second laser
        bossLasers.add(new BossLaser(x, y, 120));  
      }
      break;
    }
  }

  @Override
  void display() {
    if (bossDefeated) return;
    // spawn flash
    if (spawnFlashActive) {
      float alpha = map(spawnFlashTimer++, 0, spawnFlashDur, 255, 0);
      noStroke(); fill(255, alpha);
      rect(0, 0, width, height);
      if (spawnFlashTimer >= spawnFlashDur) spawnFlashActive = false;
    }

    // health bar
    float bw = 400, bh = 10;
    float bx = width/2 - bw/2, by = 20;
    noStroke(); fill(30); rect(bx, by, bw, bh, 5);
    float ratio = displayedHp / maxHp;
    fill(255, 0, 0); rect(bx, by, bw * ratio, bh, 5);
    noFill(); stroke(255); strokeWeight(2); rect(bx, by, bw, bh, 5);
    
    if (phase2) {
      noFill();
      stroke(255, 0, 0, 128 * (0.5f + 0.5f * sin(auraPhase)));
      strokeWeight(8);
      float r = getRadius() * 1.5f;
      ellipse(x, y, r*2, r*2);
    }

    // draw sprite at full size
    imageMode(CENTER);
    image(img, x, y, img.width * SCALE * 1.3f, img.height * SCALE * 1.3f);

    // intro spiral and effects
    if (introActive) {
      float t = constrain(introTimer / (float)introDuration, 0, 1);
      int particles = 30;
      float maxR = max(width, height);
      noStroke(); fill(255, 150);
      for (int i = 0; i < particles; i++) {
        float a = TWO_PI * i / particles + random(-0.1, 0.1);
        float r = lerp(maxR, 0, t);
        ellipse(startX + cos(a) * r, startY + sin(a) * r, 20 * (1 - t), 20 * (1 - t));
      }
      // BOSS INCOMING
      textAlign(CENTER, CENTER);
      textSize(48);
      fill(255, 0, 0, flashAlpha);
      text("BOSS INCOMING", width/2, height/2);
      return;
    }

    if (!justSpawned) {
      justSpawned = true;
      postFlashTimer = 0;
    }
    postFlashTimer = min(postFlashTimer + 1, postFlashDur);
    float flashA = map(postFlashTimer, 0, postFlashDur, 255, 0);
    noStroke(); fill(255, flashA); rect(0, 0, width, height);
    textAlign(CENTER, CENTER); textSize(48);
    fill(255, 0, 0, flashA);
    text("BOSS INCOMING", width/2, height/2);
  }

  void spawnBullet(float angle, float speed, int type) {
    float r = (img.width * SCALE * 1.3f)/3.5 + 10;
    float bx = x + cos(angle)*r, by = y + sin(angle)*r;
    PImage ref = (type==2) ? advEnemyBulletImg : veryAdvEnemyBulletImg;
    bullets.add(new Bullet(bx, by, cos(angle)*speed, sin(angle)*speed, ref, this));
  }
}

class BossLaser {
  float x, y;
  int   life, duration;
  float width = 8;

  BossLaser(float x, float y, int duration) {
    this.x = x;
    this.y = y;
    this.duration = duration;
    this.life = 0;
  }

  void update() {
    life++;
  }

  void display() {
    // a vertical beam from boss to bottom
    stroke(255, 50, 50, map(duration - life, 0, duration, 0, 200));
    strokeWeight(width);
    line(x, y + 20, x, height);
  }

  boolean finished() {
    return life >= duration;
  }
}

class HomingBullet extends Bullet {
  Player target;
  float turnRate = radians(2); // max turn per frame
  ArrayList<PVector> history;  // to store past positions
  int maxTrail = 15;           // how many points in the trail

  HomingBullet(float x, float y, Player target, PImage img, Object src) {
    super(x, y, 0, 0, img, src);
    this.target = target;
    angle = atan2(target.y - y, target.x - x);
    float speed = 8;
    vx = cos(angle) * speed;
    vy = sin(angle) * speed;
    history = new ArrayList<PVector>();
    history.add(new PVector(x, y));
  }

  @Override
  void update() {
    float desired = atan2(target.y - y, target.x - x);
    float delta   = desired - angle;
    // wrap into (-PI,PI)
    delta = (delta + PI) % TWO_PI - PI;
    angle += constrain(delta, -turnRate, turnRate);
    float speed = sqrt(vx*vx + vy*vy);
    vx = cos(angle) * speed;
    vy = sin(angle) * speed;

    super.update();

    // record for trail
    history.add(0, new PVector(x, y));
    if (history.size() > maxTrail) {
      history.remove(history.size() - 1);
    }
  }

  @Override
  void display() {
    // draw trail
    noFill();
    for (int i = 0; i < history.size(); i++) {
      float alpha = map(i, 0, history.size()-1, 200, 0);
      PVector p = history.get(i);
      stroke(255, 255, 0, alpha);
      strokeWeight(map(i, 0, history.size()-1, 4, 1));
      point(p.x, p.y);
    }

    pushMatrix();
    translate(x, y);
    rotate(angle + HALF_PI);
    imageMode(CENTER);
    image(img, 0, 0);
    popMatrix();
  }
}

ArrayList<Confetti> confetti = new ArrayList<Confetti>();
boolean victoryInit = false;

class Confetti {
  float x, y, vx, vy;
  color c;
  float size;
  Confetti() {
    x = random(width);
    y = random(-200, -20);
    vx = random(-1, 1);
    vy = random(2, 5);
    size = random(8, 16);
    c = color(random(255), random(255), random(255));
  }
  void update() {
    x += vx;
    y += vy;
  }
  void display() {
    noStroke();
    fill(c);
    pushMatrix();
    translate(x, y);
    rotate(frameCount * 0.05f);
    rect(0, 0, size, size*0.4f);
    popMatrix();
  }
}
