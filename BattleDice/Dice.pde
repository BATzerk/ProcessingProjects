int[] attackDice, defendDice;

final float BATTLE_GATHER_DURATION = 0.4;
final float BATTLE_PAIR_DELAY = 0.25;
final float BATTLE_PAIR_DURATION = 0.14;
final float BATTLE_WIN_FLASH_DURATION = 1.4;
final float BATTLE_UNDERDOG_BANNER_DURATION = 1.5;
final float BATTLE_BASH_WIND_DURATION = 0.35;
final float BATTLE_BASH_SLAM_DURATION = 0.16;
final float BATTLE_BASH_RECOIL_DURATION = 0.12;
final float BATTLE_BASH_VANISH_DURATION = 0.32;
final float BATTLE_BASH_WIND_DISTANCE = 34;
final float BATTLE_BASH_IMPACT_OVERLAP = 14;
final float BATTLE_BASH_LOSER_KNOCKBACK = 84;
final float BATTLE_BASH_VANISH_SPEED = 92;
final float BATTLE_BASH_VANISH_SPEED_RANDOM = 48;
final float BATTLE_BASH_VANISH_DRIFT_RANDOM = 46;
final float BATTLE_DIE_RADIUS = 20;
final float BATTLE_CENTER_COLUMN_OFFSET = 44;
final float BATTLE_SCORE_Y = 116;
final float BATTLE_SCORE_RECT_PAD_X = 22;
final float BATTLE_SCORE_RECT_PAD_Y = 8;
final float BATTLE_DIM_ALPHA = 120;
final float BATTLE_DIM_FADE_IN_DURATION = 0.18;
final float BATTLE_DIM_FADE_OUT_DURATION = 0.28;
BattleDie[] attackBattleDice, defendBattleDice;
float battleResolutionTime;

void setupBattle(Country offense, Country defense) {
  if (isGuaranteedBattleWin(offense, defense)) {
    moveIntoCountry(offense, defense);
    return;
  }

  attackingCountry = offense;
  defendingCountry = defense;
  isBattleMode = true;
  updateCountryDisplayOffsets();
  timeWhenStartedRolling = currTime;
  attackDice = new int[offense.myDice];
  defendDice = new int[defense.myDice];
  attackBattleDice = makeBattleDice(offense, true);
  defendBattleDice = makeBattleDice(defense, false);
  battleResolutionTime = BATTLE_GATHER_DURATION
    + max(attackDice.length, defendDice.length) * BATTLE_PAIR_DELAY
    + BATTLE_PAIR_DURATION
    + BATTLE_WIN_FLASH_DURATION;
  attackSum = 0;
  defendSum = 0;
}

boolean isGuaranteedBattleWin(Country offense, Country defense) {
  return offense.myDice > defense.myDice * DICE_SIDES;
}

int d6() {
  return floor(random(DICE_SIDES)) + 1;
}

void rollBattleDice() {
  attackSum = 0;
  for (int i = 0; i < attackDice.length; i++) {
    int roll = d6();
    attackSum += roll;
    attackDice[i] = roll;
  }
  defendSum = 0;
  for (int i = 0; i < defendDice.length; i++) {
    int roll = d6();
    defendSum += roll;
    defendDice[i] = roll;
  }
}

BattleDie[] makeBattleDice(Country country, boolean isLeftSide) {
  BattleDie[] dice = new BattleDie[country.myDice];
  int count = max(1, country.myDice);
  float sideX = isLeftSide ? 76 : width - 76;
  float centerX = width / 2 + (isLeftSide ? -BATTLE_CENTER_COLUMN_OFFSET : BATTLE_CENTER_COLUMN_OFFSET);
  float spacing = min(48, (height - 180) / max(1, count - 1));
  float firstY = height / 2 - (count - 1) * spacing / 2 + 30;
  for (int i = 0; i < country.myDice; i++) {
    PVector startPos = getCountryDieScreenPos(country, i);
    float y = firstY + i * spacing;
    dice[i] = new BattleDie(startPos, new PVector(sideX, y), new PVector(centerX, y), country.myTeamIndex);
  }
  return dice;
}

PVector getCountryDieScreenPos(Country country, int dieIndex) {
  PVector diePos = country.dieScreenPos(dieIndex);
  return new PVector(gridPos.x + diePos.x, gridPos.y + diePos.y + country.displayOffsetY);
}

float easeInOut(float t) {
  t = constrain(t, 0, 1);
  return t * t * (3 - 2 * t);
}

float battlePairStartTime(int index) {
  return BATTLE_GATHER_DURATION + index * BATTLE_PAIR_DELAY;
}

boolean isBattleFlashTime(float elapsed) {
  return elapsed >= battleResolutionTime - BATTLE_WIN_FLASH_DURATION;
}

float currentBattleResolutionTime() {
  return battleResolutionTime + (isUnderdogBattleVictory() ? BATTLE_UNDERDOG_BANNER_DURATION : 0);
}

boolean isUnderdogBattleVictory() {
  boolean attackerWins = attackSum > defendSum;
  if (attackerWins) {
    return attackDice.length < defendDice.length;
  }
  return defendDice.length < attackDice.length;
}

float battleBashStartTime() {
  return battleResolutionTime - BATTLE_WIN_FLASH_DURATION;
}

float battleBashImpactTime() {
  return battleBashStartTime() + BATTLE_BASH_WIND_DURATION + BATTLE_BASH_SLAM_DURATION;
}

void updateBattleDiceValues(float elapsed) {
  attackSum = updateBattleDiceValues(attackBattleDice, attackDice, elapsed);
  defendSum = updateBattleDiceValues(defendBattleDice, defendDice, elapsed);
}

int updateBattleDiceValues(BattleDie[] dice, int[] values, float elapsed) {
  int sum = 0;
  for (int i = 0; i < dice.length; i++) {
    if (!dice[i].isLocked && elapsed >= battlePairStartTime(i)) {
      dice[i].lockedValue = d6();
      dice[i].isLocked = true;
      values[i] = dice[i].lockedValue;
    }
    if (dice[i].isLocked) {
      sum += dice[i].lockedValue;
    }
  }
  return sum;
}

void finishBattle() {
  isBattleMode = false;
  if (attackSum > defendSum) {
    moveIntoCountry(attackingCountry, defendingCountry);
    defendingCountry.startCaptureHighlight();
  }
  else {
    attackingCountry.myDice = 1; // BONK!
    attackingCountry.startShudder();
    if (isCurrentPlayerHuman()) {
      statusText = "Attack failed. That country is down to 1 die. Attack again, or press ENTER.";
    }
    setSelectedCountryIndex(-1);
  }
}

void showBattleDice() {
  float elapsed = currTime - timeWhenStartedRolling;
  updateBattleDiceValues(elapsed);
  int winningTeamIndex = attackSum > defendSum ? attackingCountry.myTeamIndex : defendingCountry.myTeamIndex;
  boolean isFlashingWinner = isBattleFlashTime(elapsed);
  float flash = isFlashingWinner ? sinRange(currTime * 18, 0.25, 1) : 0;

  // fill(teamColor(attackingCountry.myTeamIndex, isFlashingWinner && winningTeamIndex == attackingCountry.myTeamIndex ? 185 : 110));
  // rect(0, 0, width/2, height);
  // fill(teamColor(defendingCountry.myTeamIndex, isFlashingWinner && winningTeamIndex == defendingCountry.myTeamIndex ? 185 : 110));
  // rect(width/2, 0, width/2, height);

  float dimAlpha = getBattleDimAlpha(elapsed);
  if (dimAlpha > 0) {
    fill(0, dimAlpha);
    rect(0, 0, width, height);
  }

  drawBattleScores(isFlashingWinner, winningTeamIndex, flash);
  boolean attackerWins = attackSum > defendSum;
  if (attackerWins) {
    drawBattleDiceColumn(defendBattleDice, elapsed, false, true, true, false);
    drawBattleDiceColumn(attackBattleDice, elapsed, true, false, true, false);
  }
  else {
    drawBattleDiceColumn(attackBattleDice, elapsed, true, true, false, true);
    drawBattleDiceColumn(defendBattleDice, elapsed, false, false, false, false);
  }

  drawUnderdogVictoryBanner(elapsed);
}

float getBattleDimAlpha(float elapsed) {
  float fadeIn = constrain(elapsed / BATTLE_DIM_FADE_IN_DURATION, 0, 1);
  float fadeOut = constrain((currentBattleResolutionTime() - elapsed) / BATTLE_DIM_FADE_OUT_DURATION, 0, 1);
  return BATTLE_DIM_ALPHA * min(fadeIn, fadeOut);
}

void drawBattleScores(boolean isFlashingWinner, int winningTeamIndex, float flash) {
  drawBattleScore(attackSum, width / 2 - BATTLE_CENTER_COLUMN_OFFSET, BATTLE_SCORE_Y, attackingCountry.myTeamIndex, isFlashingWinner && winningTeamIndex == attackingCountry.myTeamIndex, flash, RIGHT);
  drawBattleScore(defendSum, width / 2 + BATTLE_CENTER_COLUMN_OFFSET, BATTLE_SCORE_Y, defendingCountry.myTeamIndex, isFlashingWinner && winningTeamIndex == defendingCountry.myTeamIndex, flash, LEFT);
}

void drawBattleScore(int score, float x, float y, int teamIndex, boolean isWinner, float flash, int horizontalAlign) {
  String scoreText = str(score);
  textAlign(horizontalAlign, CENTER);
  textSize(isWinner ? 80 + flash * 12 : 80);
  float textCenterX = x;
  if (horizontalAlign == RIGHT) {
    textCenterX -= textWidth(scoreText) / 2;
  }
  else if (horizontalAlign == LEFT) {
    textCenterX += textWidth(scoreText) / 2;
  }

  if (isWinner) {
    noStroke();
    fill(teamColor(teamIndex, 120));
    rectMode(CENTER);
    rect(textCenterX, y, textWidth(scoreText) + BATTLE_SCORE_RECT_PAD_X * 2, textAscent() + textDescent() + BATTLE_SCORE_RECT_PAD_Y * 2);
    rectMode(CORNER);
  }
  fill(0, 170);
  text(scoreText, x + 2, y + 3);
  fill(teamColor(teamIndex));
  text(scoreText, x, y);
  textAlign(CENTER, CENTER);
}

void drawUnderdogVictoryBanner(float elapsed) {
  if (!isUnderdogBattleVictory() || elapsed < battleResolutionTime) {
    return;
  }

  float bannerElapsed = elapsed - battleResolutionTime;
  float fadeIn = constrain(bannerElapsed / 0.18, 0, 1);
  float fadeOut = constrain((BATTLE_UNDERDOG_BANNER_DURATION - bannerElapsed) / 0.25, 0, 1);
  float alphaValue = 255 * min(fadeIn, fadeOut);
  float y = height / 2 - 138;

  pushStyle();
  rectMode(CENTER);
  textAlign(CENTER, CENTER);
  textSize(42);
  noStroke();
  fill(0, alphaValue * 0.62);
  rect(width / 2 + 4, y + 5, 500, 68, 6);
  fill(42, 190, 255, alphaValue);
  rect(width / 2, y, 500, 68, 6);
  stroke(255, alphaValue * 0.8);
  strokeWeight(2);
  noFill();
  rect(width / 2, y, 492, 60, 6);
  fill(0, alphaValue * 0.72);
  text("UNDERDOG VICTORY!", width / 2 + 2, y + 4);
  fill(255, alphaValue);
  text("UNDERDOG VICTORY!", width / 2, y);
  popStyle();
}

void drawBattleDiceColumn(BattleDie[] dice, float elapsed, boolean isAttacker, boolean isLoser, boolean isRightSide, boolean loserKeepsOneDie) {
  float bashOffsetX = getBattleBashOffset(elapsed, isAttacker, isLoser, isRightSide);
  int survivorIndex = dice.length / 2;
  for (int i = 0; i < dice.length; i++) {
    BattleDie die = dice[i];
    float pairStart = battlePairStartTime(i);
    PVector pos;
    if (elapsed < BATTLE_GATHER_DURATION) {
      pos = PVector.lerp(die.startPos, die.sidePos, easeInOut(elapsed / BATTLE_GATHER_DURATION));
    }
    else if (elapsed < pairStart) {
      pos = die.sidePos.copy();
    }
    else {
      pos = PVector.lerp(die.sidePos, die.centerPos, easeInOut((elapsed - pairStart) / BATTLE_PAIR_DURATION));
    }
    pos.x += bashOffsetX;

    boolean isSurvivor = loserKeepsOneDie && i == survivorIndex;
    float alpha = getBattleDieAlpha(elapsed, isLoser, isSurvivor);
    if (alpha <= 0) {
      continue;
    }
    float vanish = getBattleDieVanish(elapsed, isLoser, isSurvivor);
    if (vanish > 0) {
      pos.add(PVector.mult(die.vanishVelocity, vanish * BATTLE_BASH_VANISH_DURATION));
    }
    float radius = BATTLE_DIE_RADIUS * (1 + vanish * 0.45);
    int faceValue = die.isLocked ? die.lockedValue : floor(random(DICE_SIDES)) + 1;
    drawDieFace(pos.x, pos.y, radius, faceValue, teamColor(die.teamIndex), alpha);
  }
}

float getBattleBashOffset(float elapsed, boolean isAttacker, boolean isLoser, boolean isRightSide) {
  float bashElapsed = elapsed - battleBashStartTime();
  if (bashElapsed <= 0) {
    return 0;
  }

  if (isAttacker) {
    float slamDirection = 1;
    float windOffset = -slamDirection * BATTLE_BASH_WIND_DISTANCE;
    float impactOffset = slamDirection * (BATTLE_CENTER_COLUMN_OFFSET * 2 + BATTLE_BASH_IMPACT_OVERLAP);
    float settleOffset = 0;

    if (bashElapsed < BATTLE_BASH_WIND_DURATION) {
      return lerp(0, windOffset, easeInOut(bashElapsed / BATTLE_BASH_WIND_DURATION));
    }
    bashElapsed -= BATTLE_BASH_WIND_DURATION;

    if (bashElapsed < BATTLE_BASH_SLAM_DURATION) {
      float t = bashElapsed / BATTLE_BASH_SLAM_DURATION;
      return lerp(windOffset, impactOffset, t * t);
    }
    bashElapsed -= BATTLE_BASH_SLAM_DURATION;

    if (bashElapsed < BATTLE_BASH_RECOIL_DURATION) {
      return lerp(impactOffset, settleOffset, easeInOut(bashElapsed / BATTLE_BASH_RECOIL_DURATION));
    }
    return settleOffset;
  }

  if (!isLoser) {
    return 0;
  }

  float loserDirection = isRightSide ? 1 : -1;
  float impactElapsed = elapsed - battleBashImpactTime();
  if (impactElapsed <= 0 || impactElapsed > BATTLE_BASH_RECOIL_DURATION + BATTLE_BASH_VANISH_DURATION) {
    return 0;
  }
  float t = impactElapsed / (BATTLE_BASH_RECOIL_DURATION + BATTLE_BASH_VANISH_DURATION);
  return loserDirection * sin(t * PI) * BATTLE_BASH_LOSER_KNOCKBACK;
}

float getBattleDieAlpha(float elapsed, boolean isLoser, boolean isSurvivor) {
  if (!isLoser || isSurvivor || elapsed < battleBashImpactTime()) {
    return 255;
  }
  float t = constrain((elapsed - battleBashImpactTime()) / BATTLE_BASH_VANISH_DURATION, 0, 1);
  return lerp(255, 0, easeInOut(t));
}

float getBattleDieVanish(float elapsed, boolean isLoser, boolean isSurvivor) {
  if (!isLoser || isSurvivor || elapsed < battleBashImpactTime()) {
    return 0;
  }
  return easeInOut((elapsed - battleBashImpactTime()) / BATTLE_BASH_VANISH_DURATION);
}

void drawDieFace(float x, float y, float radius, int value, color dieColor) {
  drawDieFace(x, y, radius, value, dieColor, 255);
}

void drawDieFace(float x, float y, float radius, int value, color dieColor, float alphaValue) {
  pushStyle();
  color visibleDieColor = color(hue(dieColor), saturation(dieColor), brightness(dieColor), alphaValue);
  color faceColor = lerpColor(color(0, 0, 255, alphaValue), visibleDieColor, 0.22);
  fill(faceColor);
  stroke(visibleDieColor);
  strokeWeight(2);
  rectMode(CENTER);
  rect(x, y, radius * 2, radius * 2);

  noStroke();
  fill(0, 0, 35, min(220, alphaValue));
  float pipOffset = radius * 0.6;
  float pipSize = radius * 0.48;
  if (value == 1 || value == 3 || value == 5) {
    ellipse(x, y, pipSize, pipSize);
  }
  if (value >= 2) {
    ellipse(x - pipOffset, y - pipOffset, pipSize, pipSize);
    ellipse(x + pipOffset, y + pipOffset, pipSize, pipSize);
  }
  if (value >= 4) {
    ellipse(x + pipOffset, y - pipOffset, pipSize, pipSize);
    ellipse(x - pipOffset, y + pipOffset, pipSize, pipSize);
  }
  if (value == 6) {
    ellipse(x - pipOffset, y, pipSize, pipSize);
    ellipse(x + pipOffset, y, pipSize, pipSize);
  }
  popStyle();
}

class BattleDie
{
  PVector startPos;
  PVector sidePos;
  PVector centerPos;
  int teamIndex;
  int lockedValue = 0;
  boolean isLocked = false;
  PVector vanishVelocity;

  BattleDie(PVector startPos, PVector sidePos, PVector centerPos, int teamIndex) {
    this.startPos = startPos;
    this.sidePos = sidePos;
    this.centerPos = centerPos;
    this.teamIndex = teamIndex;
    float bashDirection = centerPos.x < width / 2 ? -1 : 1;
    float speed = BATTLE_BASH_VANISH_SPEED + random(BATTLE_BASH_VANISH_SPEED_RANDOM);
    this.vanishVelocity = new PVector(
      bashDirection * speed,
      random(-BATTLE_BASH_VANISH_DRIFT_RANDOM, BATTLE_BASH_VANISH_DRIFT_RANDOM)
    );
  }
}
