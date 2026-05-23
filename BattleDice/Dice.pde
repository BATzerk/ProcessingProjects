int[] attackDice, defendDice;

final float BATTLE_GATHER_DURATION = 0.4;
final float BATTLE_PAIR_DELAY = 0.25;
final float BATTLE_PAIR_DURATION = 0.14;
final float BATTLE_WIN_FLASH_DURATION = 1.4;
final float BATTLE_DIE_RADIUS = 20;
final float BATTLE_CENTER_COLUMN_OFFSET = 44;
BattleDie[] attackBattleDice, defendBattleDice;
float battleResolutionTime;

void setupBattle(Country offense, Country defense) {
  if (isGuaranteedBattleWin(offense, defense)) {
    moveIntoCountry(offense, defense);
    return;
  }

  attackingCountry = offense;
  defendingCountry = defense;
  timeWhenStartedRolling = currTime;
  attackDice = new int[offense.myDice];
  defendDice = new int[defense.myDice];
  attackBattleDice = makeBattleDice(offense, true);
  defendBattleDice = makeBattleDice(defense, false);
  battleResolutionTime = BATTLE_GATHER_DURATION
    + max(attackDice.length, defendDice.length) * BATTLE_PAIR_DELAY
    + BATTLE_PAIR_DURATION
    + BATTLE_WIN_FLASH_DURATION;
  isBattleMode = true;
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
  Cell cell = (Cell) country.cells.get(dieIndex);
  return new PVector(gridPos.x + cell.screenPos.x, gridPos.y + cell.screenPos.y + country.displayOffsetY);
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
  }
  else {
    attackingCountry.myDice = 1; // BONK!
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

  fill(0, 120);
  rect(0, 0, width, height);

  drawBattleScores(isFlashingWinner, winningTeamIndex, flash);
  drawBattleDiceColumn(attackBattleDice, elapsed);
  drawBattleDiceColumn(defendBattleDice, elapsed);
}

void drawBattleScores(boolean isFlashingWinner, int winningTeamIndex, float flash) {
  drawBattleScore(attackSum, width / 2 - BATTLE_CENTER_COLUMN_OFFSET, 78, attackingCountry.myTeamIndex, isFlashingWinner && winningTeamIndex == attackingCountry.myTeamIndex, flash, RIGHT);
  drawBattleScore(defendSum, width / 2 + BATTLE_CENTER_COLUMN_OFFSET, 78, defendingCountry.myTeamIndex, isFlashingWinner && winningTeamIndex == defendingCountry.myTeamIndex, flash, LEFT);
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
    ellipse(textCenterX, y, 130, 82);
  }
  fill(0, 170);
  text(scoreText, x + 2, y + 3);
  fill(teamColor(teamIndex));
  text(scoreText, x, y);
  textAlign(CENTER, CENTER);
}

void drawBattleDiceColumn(BattleDie[] dice, float elapsed) {
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
    int faceValue = die.isLocked ? die.lockedValue : floor(random(DICE_SIDES)) + 1;
    drawDieFace(pos.x, pos.y, BATTLE_DIE_RADIUS, faceValue, teamColor(die.teamIndex));
  }
}

void drawDieFace(float x, float y, float radius, int value, color dieColor) {
  pushStyle();
  color faceColor = lerpColor(color(0, 0, 255), dieColor, 0.22);
  fill(faceColor);
  stroke(dieColor);
  strokeWeight(2);
  rectMode(CENTER);
  rect(x, y, radius * 2, radius * 2);

  noStroke();
  fill(0, 0, 35, 220);
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

  BattleDie(PVector startPos, PVector sidePos, PVector centerPos, int teamIndex) {
    this.startPos = startPos;
    this.sidePos = sidePos;
    this.centerPos = centerPos;
    this.teamIndex = teamIndex;
  }
}
