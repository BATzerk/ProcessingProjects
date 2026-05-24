// BattleDice
// by Chris Hallberg and Brett Taylor
// Based on the game "Battle Dice" from 20 Games to Play with Your Mates

/**
 * HOUSECLEANING TODO
 * - Move pure game rules into a small, testable rules layer.
 * - Keep render code out of Country where possible.
 * - Replace ad-hoc timers with a single action scheduler.
 * - Add lightweight verification for odds, legal moves, capture, and migration.
 */

// Tweakables
final int NUM_STARTING_DICE_PER_TEAM = 6;
final int MIN_CELLS_PER_COUNTRY = 5;
final int MAX_CELLS_PER_COUNTRY = 12;
final int GRID_WIDTH = 24;
final int GRID_HEIGHT = 18;
final int EDGE_LAND_AVOIDANCE_DISTANCE = 2;
final float EDGE_LAND_GENERATION_CHANCE_PER_STEP = 0.4;
final int STARTING_COUNTRY_MIN_DISTANCE = 3;
// Constants
final boolean MOVIE_MODE = false;
final boolean RUN_STARTUP_RULE_CHECKS = true;
int NUM_PLAYERS = 4;
final int HUMAN_PLAYER_INDEX = 0;
final int NUM_FACES = 6; // it's hip to be hex.
final int DICE_SIDES = 6;
final float NORMAL_TIME_SCALE = 1;
final float FAST_FORWARD_TIME_SCALE = 6;
final float SELECTED_COUNTRY_RAISE = -7;
final float BATTLE_COUNTRY_RAISE = -7;
final float SELECTED_COUNTRY_BOB_AMOUNT = 0.6;
final float SELECTED_COUNTRY_BOB_SPEED = 4;
final float PLAYER_BANNER_HEIGHT = 42;
final float ACTIVE_PLAYER_BANNER_HEIGHT = 64;
final float END_TURN_BUTTON_WIDTH = 134;
final float END_TURN_BUTTON_HEIGHT = 42;
final float END_TURN_BUTTON_MARGIN = 16;
final float END_TURN_BUTTON_RADIUS = 6;
final float WIN_CHANCE_TOOLTIP_PAD_X = 10;
final float WIN_CHANCE_TOOLTIP_PAD_Y = 7;
final float WIN_CHANCE_TOOLTIP_RADIUS = 5;
final int PLAYER_LUCK_DECIMALS = 1;
final float MIGRATION_DURATION = 0.65;
final float MIGRATION_DIE_STAGGER = 0.055;
final float MIGRATION_DIE_ARC_HEIGHT = 42;
final int GAME_MODE_PLAYER_SELECT = 0;
final int GAME_MODE_HUMAN_TURN = 1;
final int GAME_MODE_AI_TURN = 2;
final int GAME_MODE_BATTLE = 3;
final int GAME_MODE_MIGRATION = 4;
final int GAME_MODE_GAME_OVER = 5;
final int SCHEDULED_ACTION_NONE = 0;
final int SCHEDULED_ACTION_AI_STEP = 1;
final int SCHEDULED_ACTION_MOVIE_RESTART = 2;

// Grid Properties
float tileRadius = 22;
float hexRatio = 0.8457;
PVector gridPos; // the TOP-left corner of the grid.
Cell[][] gridCells;
Country[] countries=new Country[0];
float[][] diceSumOddsCache = new float[MAX_CELLS_PER_COUNTRY + 1][];
float[][] winChanceCache = new float[MAX_CELLS_PER_COUNTRY + 1][MAX_CELLS_PER_COUNTRY + 1];
boolean[][] winChanceCached = new boolean[MAX_CELLS_PER_COUNTRY + 1][MAX_CELLS_PER_COUNTRY + 1];

// Game Loop
int gameMode = MOVIE_MODE ? GAME_MODE_AI_TURN : GAME_MODE_PLAYER_SELECT;
int currPlayerIndex;
boolean[] eliminated;
String currPlayerName;
boolean doHideBattleDice=false;
AI[] botPlayers;
String statusText = "";
int scheduledAction = SCHEDULED_ACTION_NONE;
float timeWhenScheduledAction;
// Time Variables
float currTime; // in SECONDS.
float timeScale = NORMAL_TIME_SCALE; // how fast currTime advances is scaled by this.
int pmillis; // previous millis.

int turnCount;
int selectedCountryIndex;

Country attackingCountry, defendingCountry;
int attackSum, defendSum;
float timeWhenStartedRolling;
Country migrationFromCountry, migrationToCountry;
int migrationDiceCount;
PVector[] migrationDieStartPositions;
PVector[] migrationDieEndPositions;
float timeWhenStartedMigration;


// ======== SETUP ========
void setup() {
  colorMode(HSB);
  size(1024, 768);
  textAlign(CENTER, CENTER);
  // textFont(loadFont("AdobeDevanagari-Bold-48.vlw"));
  pmillis = millis();
  if (RUN_STARTUP_RULE_CHECKS) {
    runStartupRuleChecks();
  }
  if (MOVIE_MODE) {
    startNewGame();
  }
}


// ======== DRAW ========
void draw() {
  background(0x1F85DE);
  
  // Update timeElapsed.
  currTime += (millis()-pmillis) * 0.001 * timeScale;
  pmillis = millis();
  
  runDueScheduledAction();

  if (isPlayerSelectScreen()) {
    drawPlayerSelectScreen();
    return;
  }
  
  // DRAW!
  drawGridCells();
  drawAttackWinChanceTooltip();
  drawMigrationDice();

  if (isMigrationMode() && currTime - timeWhenStartedMigration > currentMigrationDuration()) {
    finishMigrationDice();
  }

  // ---- BATTLE MODE ----
  if (isBattleMode()) {
    float beenRollingFor = currTime - timeWhenStartedRolling;
    if (!doHideBattleDice) {
      showBattleDice();
    }
    else {
      updateBattleDiceValues(beenRollingFor);
    }
    if (beenRollingFor > currentBattleResolutionTime()) {
      finishBattle();
    }
  }

  if (!MOVIE_MODE) {
    drawCurrentPlayerHeader();
    drawEndTurnButton();
  }
}

void drawGridCells() {
  updateCountryDisplayOffsets();

  pushMatrix();
  translate(gridPos.x, gridPos.y);

  for (int i=0; i<countries.length; i++) {
    if (isCountryRaisedForDrawing(i)) {
      continue;
    } // skip raised-up countries.
    countries[i].drawMyCellsShadow();
  }
  for (int i=0; i<countries.length; i++) {
    if (isCountryRaisedForDrawing(i)) {
      continue;
    } // skip raised-up countries.
    countries[i].drawMyCellsFill();
  }

  for (int i=0; i<countries.length; i++) {
    if (isCountryRaisedForDrawing(i)) {
      continue;
    } // draw raised-up countries after everything else.
    countries[i].drawNormalBorders();
  }

  // Draw attackable borders late so neighboring countries cannot stamp over them.
  for (int i=0; i<countries.length; i++) {
    countries[i].drawAttackableBorders();
  }
  for (int i=0; i<countries.length; i++) {
    countries[i].drawHoveredAttackBorder();
  }

  // Draw raised-up countries last so they visually sit above the map.
  for (int i=0; i<countries.length; i++) {
    if (isCountryRaisedForDrawing(i)) {
      countries[i].drawMyCellsShadow();
      countries[i].drawMyCellsFill();
      countries[i].drawNormalBorders();
    }
  }

  popMatrix();
}

void drawAttackWinChanceTooltip() {
  if (!isCurrentPlayerHuman() || isBattleMode() || isGameOver() || selectedCountryIndex < 0) {
    return;
  }

  Country attacker = countries[selectedCountryIndex];
  Country defender = getCountryByScreenPos(mouseX, mouseY);
  if (!canAttackCountry(attacker, defender)) {
    return;
  }

  int winPercent = round(getWinChance(attacker.myDice, defender.myDice) * 100);
  String label = winPercent + "% TO WIN";

  pushStyle();
  rectMode(CORNER);
  textAlign(CENTER, CENTER);
  textSize(15);
  float tooltipWidth = textWidth(label) + WIN_CHANCE_TOOLTIP_PAD_X * 2;
  float tooltipHeight = textAscent() + textDescent() + WIN_CHANCE_TOOLTIP_PAD_Y * 2;
  float x = constrain(mouseX + 16, 8, width - tooltipWidth - 8);
  float y = constrain(mouseY - tooltipHeight - 14, ACTIVE_PLAYER_BANNER_HEIGHT + 8, height - tooltipHeight - 42);
  noStroke();
  fill(0, 115);
  rect(x + 3, y + 4, tooltipWidth, tooltipHeight, WIN_CHANCE_TOOLTIP_RADIUS);
  fill(teamHue(currPlayerIndex), 145, 245);
  rect(x, y, tooltipWidth, tooltipHeight, WIN_CHANCE_TOOLTIP_RADIUS);
  stroke(255, 210);
  strokeWeight(1.5);
  noFill();
  rect(x + 1, y + 1, tooltipWidth - 2, tooltipHeight - 2, WIN_CHANCE_TOOLTIP_RADIUS);
  fill(0, 180);
  text(label, x + tooltipWidth / 2 + 1, y + tooltipHeight / 2 + 2);
  fill(255);
  text(label, x + tooltipWidth / 2, y + tooltipHeight / 2);
  popStyle();
}

void drawCurrentPlayerHeader() {
  noStroke();
  float bannerWidth = width / (float) NUM_PLAYERS;
  for (int i = 0; i < NUM_PLAYERS; i++) {
    boolean isActive = i == currPlayerIndex;
    float x = i * bannerWidth;
    float bannerHeight = isActive ? ACTIVE_PLAYER_BANNER_HEIGHT : PLAYER_BANNER_HEIGHT;
    color bannerColor = isActive
      ? teamColor(i)
      : color(teamHue(i), eliminated[i] ? 24 : 96, eliminated[i] ? 74 : 132);

    fill(bannerColor);
    rect(x, 0, bannerWidth + 1, bannerHeight);
    fill(0, isActive ? 55 : 85);
    rect(x, bannerHeight - 6, bannerWidth + 1, 6);
    fill(0, 70);
    rect(x + bannerWidth - 1, 0, 1, bannerHeight);

    fill(isActive ? 0 : 255);
    textSize(isActive ? 24 : 16);
    text(getPlayerName(i), x + bannerWidth/2, isActive ? 21 : 14);
    textSize(isActive ? 34 : 18);
    text(getPlayerDiceTotal(i) + " dice", x + bannerWidth/2, isActive ? 48 : 31);
    drawPlayerLuckiness(i, x, bannerWidth, isActive);
  }

  fill(0, 150);
  rect(0, height - 34, width, 34);
  fill(255);
  textSize(16);
  String helpText = isCurrentPlayerHuman()
    ? "Click your lit country, then a neighboring enemy, empty country, or connected own country with room. ENTER ends turn. Hold F to fast-forward. CTRL+R restarts."
    : currPlayerName + " is thinking...";
  if (isGameOver()) {
    helpText = currPlayerName + " wins. Press CTRL+R for a new game.";
  } else if (statusText.length() > 0) {
    helpText = statusText;
  }
  text(helpText, width/2, height - 17);
}

void drawEndTurnButton() {
  if (!shouldShowEndTurnButton()) {
    return;
  }

  boolean isHovered = isMouseOverEndTurnButton();
  boolean noMoves = !currentPlayerHasAvailableMove();
  float flash = noMoves ? sinRange(currTime * 8, 0, 1) : 0;
  float x = getEndTurnButtonX();
  float y = getEndTurnButtonY();

  pushStyle();
  rectMode(CORNER);
  noStroke();
  fill(0, 95);
  rect(x + 3, y + 4, END_TURN_BUTTON_WIDTH, END_TURN_BUTTON_HEIGHT, END_TURN_BUTTON_RADIUS);

  color baseColor = color(teamHue(currPlayerIndex), 118, isHovered ? 255 : 224);
  color flashColor = color(42, 190, 255);
  fill(noMoves ? lerpColor(baseColor, flashColor, flash) : baseColor);
  rect(x, y, END_TURN_BUTTON_WIDTH, END_TURN_BUTTON_HEIGHT, END_TURN_BUTTON_RADIUS);

  stroke(255, isHovered ? 230 : 130);
  strokeWeight(isHovered ? 2.5 : 1.5);
  noFill();
  rect(x + 1, y + 1, END_TURN_BUTTON_WIDTH - 2, END_TURN_BUTTON_HEIGHT - 2, END_TURN_BUTTON_RADIUS);

  fill(0, 165);
  textSize(16);
  text("END TURN", x + END_TURN_BUTTON_WIDTH / 2 + 1, y + END_TURN_BUTTON_HEIGHT / 2 + 2);
  fill(255);
  text("END TURN", x + END_TURN_BUTTON_WIDTH / 2, y + END_TURN_BUTTON_HEIGHT / 2);
  popStyle();
}

void drawHexagon(PVector pos) {
  drawHexagon(pos.x, pos.y, tileRadius);
}
void drawHexagon(float x, float y) {
  drawHexagon(x, y, tileRadius);
}
void drawHexagon(PVector pos, float radius) {
  drawHexagon(pos.x, pos.y, radius);
}
void drawHexagon(float x, float y, float radius) {
  translate( x, y); // pushMatrix
  beginShape();
  vertex(radius*hexRatio, radius*0.5);
  vertex(0, radius);
  vertex(-radius*hexRatio, radius*0.5);
  vertex(-radius*hexRatio, -radius*0.5);
  vertex(0, -radius);
  vertex( radius*hexRatio, -radius*0.5);
  vertex( radius*hexRatio, radius*0.5);
  endShape();
  translate(-x, -y); // popMatrix
}
void drawHexLine(Vector2Int gridPos, int face) {
  pushMatrix();
  translate(getScreenX(gridPos.x, gridPos.y), getScreenY(gridPos.y));
  switch (face) {
  case 0: 
    line(0, -tileRadius, tileRadius*hexRatio, -tileRadius*0.5); 
    break;
  case 1: 
    line( tileRadius*hexRatio, -tileRadius*0.5, tileRadius*hexRatio, tileRadius*0.5); 
    break;
  case 2: 
    line(tileRadius*hexRatio, tileRadius*0.5, 0, tileRadius); 
    break;
  case 3: 
    line(0, tileRadius, -tileRadius*hexRatio, tileRadius*0.5); 
    break;
  case 4: 
    line(-tileRadius*hexRatio, tileRadius*0.5, -tileRadius*hexRatio, -tileRadius*0.5); 
    break;
  case 5: 
    line(-tileRadius*hexRatio, -tileRadius*0.5, 0, -tileRadius); 
    break;
  }
  popMatrix();
}
