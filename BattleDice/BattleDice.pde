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
final boolean DEBUG_SKIP_MENU_SCREEN = true;
final int DEBUG_STARTING_PLAYER_INDEX = 1;
final int NUM_STARTING_DICE_PER_TEAM = 6;
final int MIN_CELLS_PER_COUNTRY = 5;
final int MAX_CELLS_PER_COUNTRY = 12;
final int GRID_WIDTH = 24;
final int GRID_HEIGHT = 18;

final int EDGE_LAND_AVOIDANCE_DISTANCE = 2;
final float EDGE_LAND_GENERATION_CHANCE_PER_STEP = 0.4;
final int STARTING_COUNTRY_MIN_DISTANCE = 3;
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
final float BOARD_MIN_SIDE_PADDING = 28;
final float BASE_TILE_RADIUS = 22;
final float BOARD_TOP_PADDING = 8;
final float BOARD_BOTTOM_PADDING = 34;
final float BOARD_FIT_EXTRA_PADDING = 12;
final float BOARD_MIN_TILE_RADIUS = 0.1;
final float WIN_CHANCE_TOOLTIP_PAD_X = 10;
final float WIN_CHANCE_TOOLTIP_PAD_Y = 7;
final float WIN_CHANCE_TOOLTIP_RADIUS = 5;
final int PLAYER_LUCK_DECIMALS = 1;
final float MIGRATION_DURATION = 0.65;
final float MIGRATION_DIE_STAGGER = 0.055;
final float MIGRATION_DIE_ARC_HEIGHT = 42;
// Constants
final int HUMAN_PLAYER_INDEX = 0;
final int NO_COUNTRY = -1;
final int NO_TEAM = -1;
final int UNKNOWN_BOARD_SIZE = -1;
final int HEX_SIDES = 6;
final int DICE_SIDES = 6;
final float NORMAL_TIME_SCALE = 1;
final float FAST_FORWARD_TIME_SCALE = 6;
final float DEBUG_TIME_SCALE = 1000;
final int GAME_MODE_PLAYER_SELECT = 0;
final int GAME_MODE_HUMAN_TURN = 1;
final int GAME_MODE_AI_TURN = 2;
final int GAME_MODE_BATTLE = 3;
final int GAME_MODE_MIGRATION = 4;
final int GAME_MODE_GAME_OVER = 5;
final int SCHEDULED_ACTION_NONE = 0;
final int SCHEDULED_ACTION_AI_STEP = 1;
final String BACKGROUND_IMAGE_PATH = "background.png";
final String HEX_TILE_IMAGE_PATH = "hex-tile.png";
final String HEX_TILE_OVERLAY_IMAGE_PATH = "hex-tile-overlay.png";

// Grid Properties
float tileRadius = 22;
float hexRatio = 0.8457;
final float HEX_CELL_RENDER_BUFFER = 1;
PVector gridPos; // the TOP-left corner of the grid.
int boardLayoutWidth = UNKNOWN_BOARD_SIZE;
int boardLayoutHeight = UNKNOWN_BOARD_SIZE;
Cell[][] gridCells;
Country[] countries=new Country[0];
PImage backgroundImage;
PImage hexTileImage;
PImage hexTileOverlayImage;
float[][] diceSumOddsCache = new float[MAX_CELLS_PER_COUNTRY + 1][];
float[][] winChanceCache = new float[MAX_CELLS_PER_COUNTRY + 1][MAX_CELLS_PER_COUNTRY + 1];
boolean[][] winChanceCached = new boolean[MAX_CELLS_PER_COUNTRY + 1][MAX_CELLS_PER_COUNTRY + 1];

// Game Loop
int gameMode = DEBUG_SKIP_MENU_SCREEN ? GAME_MODE_HUMAN_TURN : GAME_MODE_PLAYER_SELECT;
int playerCount = 4;
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
  size(1024, 768, OPENGL);
  surface.setResizable(true);
  colorMode(HSB);
  textAlign(CENTER, CENTER);
  // textFont(loadFont("AdobeDevanagari-Bold-48.vlw"));
  loadImageAssets();
  updateBoardLayout();
  pmillis = millis();
  runStartupRuleChecks();
  if (DEBUG_SKIP_MENU_SCREEN) {
    startNewGame();
  }
}


// ======== DRAW ========
void draw() {
  updateBoardLayout();
  drawBackground();
  
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

  drawCurrentPlayerHeader();
  drawEndTurnButton();
  drawDiceHistoryGraph();
}

void updateBoardLayout() {
  if (width == boardLayoutWidth && height == boardLayoutHeight) {
    return;
  }

  boardLayoutWidth = width;
  boardLayoutHeight = height;
  applyBoardLayout();
}

void applyBoardLayout() {
  float fitLeft = min(BOARD_MIN_SIDE_PADDING, max(0, width * 0.08));
  float fitTop = min(ACTIVE_PLAYER_BANNER_HEIGHT + BOARD_TOP_PADDING, max(0, height * 0.18));
  float fitRight = max(fitLeft + 1, width - fitLeft);
  float fitBottom = max(fitTop + 1, height - min(34 + BOARD_BOTTOM_PADDING, max(0, height * 0.12)));
  float fitWidth = fitRight - fitLeft;
  float fitHeight = fitBottom - fitTop;
  float fitExtraPadding = min(BOARD_FIT_EXTRA_PADDING, max(0, min(fitWidth, fitHeight) * 0.18));
  float boardUnitWidth = getBoardUnitWidth();
  float boardUnitHeight = getBoardUnitHeight();
  float geometryFitWidth = max(1, fitWidth - fitExtraPadding * 2);
  float geometryFitHeight = max(1, fitHeight - fitExtraPadding * 2);

  tileRadius = max(BOARD_MIN_TILE_RADIUS, min(geometryFitWidth / boardUnitWidth, geometryFitHeight / boardUnitHeight));

  float boardMinX = getBoardMinX() - fitExtraPadding;
  float boardMinY = getBoardMinY() - fitExtraPadding;
  float boardWidth = getBoardWidth() + fitExtraPadding * 2;
  float boardHeight = getBoardHeight() + fitExtraPadding * 2;
  gridPos = new PVector(
    fitLeft + (fitWidth - boardWidth) / 2 - boardMinX,
    fitTop + (fitHeight - boardHeight) / 2 - boardMinY
  );

  updateCellScreenPositions();
}

float boardScale() {
  return tileRadius / BASE_TILE_RADIUS;
}

void scaledStrokeWeight(float baseWeight) {
  strokeWeight(max(0.5, baseWeight * boardScale()));
}

void updateCellScreenPositions() {
  if (gridCells == null) {
    return;
  }

  for (int col = 0; col < gridCells.length; col++) {
    for (int row = 0; row < gridCells[col].length; row++) {
      gridCells[col][row].screenPos.x = getScreenX(col, row);
      gridCells[col][row].screenPos.y = getScreenY(row);
    }
  }
}

float getBoardUnitWidth() {
  return getBoardWidthForRadius(1);
}

float getBoardUnitHeight() {
  return getBoardHeightForRadius(1);
}

float getBoardWidth() {
  return getBoardWidthForRadius(tileRadius);
}

float getBoardHeight() {
  return getBoardHeightForRadius(tileRadius);
}

float getBoardWidthForRadius(float radius) {
  return getBoardMaxXForRadius(radius) - getBoardMinXForRadius(radius);
}

float getBoardHeightForRadius(float radius) {
  return getBoardMaxYForRadius(radius) - getBoardMinYForRadius(radius);
}

float getBoardMinX() {
  return getBoardMinXForRadius(tileRadius);
}

float getBoardMinY() {
  return getBoardMinYForRadius(tileRadius);
}

float getBoardMaxX() {
  return getBoardMaxXForRadius(tileRadius);
}

float getBoardMaxY() {
  return getBoardMaxYForRadius(tileRadius);
}

float getBoardMinXForRadius(float radius) {
  return -radius * hexRatio;
}

float getBoardMinYForRadius(float radius) {
  return -radius;
}

float getBoardMaxXForRadius(float radius) {
  float rightmostCenter = (GRID_WIDTH - 1) * radius * 2 * hexRatio;
  rightmostCenter += radius * hexRatio;
  return rightmostCenter + radius * hexRatio;
}

float getBoardMaxYForRadius(float radius) {
  return (GRID_HEIGHT - 1) * radius * 3 / 2 + radius;
}

void loadImageAssets() {
  backgroundImage = loadImage(BACKGROUND_IMAGE_PATH);
  hexTileImage = loadImage(HEX_TILE_IMAGE_PATH);
  hexTileOverlayImage = loadImage(HEX_TILE_OVERLAY_IMAGE_PATH);
}

void drawBackground() {
  if (backgroundImage == null) {
    background(0x1F85DE);
    return;
  }

  background(0);
  float imageScale = max(width / (float)backgroundImage.width, height / (float)backgroundImage.height);
  float drawWidth = backgroundImage.width * imageScale;
  float drawHeight = backgroundImage.height * imageScale;
  imageMode(CORNER);
  image(backgroundImage, (width - drawWidth) / 2, (height - drawHeight) / 2, drawWidth, drawHeight);
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
  scaledStrokeWeight(1.5);
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
  float bannerWidth = width / (float) playerCount;
  for (int i = 0; i < playerCount; i++) {
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
  scaledStrokeWeight(isHovered ? 2.5 : 1.5);
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

void drawHexTileImage(PVector pos, color tileColor) {
  if (hexTileImage == null) {
    return;
  }

  int tileWidth = round((tileRadius + HEX_CELL_RENDER_BUFFER) * hexRatio * 2);
  int tileHeight = round((tileRadius + HEX_CELL_RENDER_BUFFER) * 2);
  imageMode(CENTER);
  tint(tileColor);
  image(hexTileImage, pos.x, pos.y, tileWidth, tileHeight);
  noTint();
}

void drawHexTileOverlayImage(PVector pos) {
  if (hexTileOverlayImage == null) {
    return;
  }

  int tileWidth = round((tileRadius + HEX_CELL_RENDER_BUFFER) * hexRatio * 2);
  int tileHeight = round((tileRadius + HEX_CELL_RENDER_BUFFER) * 2);
  imageMode(CENTER);
  image(hexTileOverlayImage, pos.x, pos.y, tileWidth, tileHeight);
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
