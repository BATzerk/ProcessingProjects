// BattleDice
// by Chris Hallberg and Brett Taylor
// Based on the game "Battle Dice" from 20 Games to Play with Your Mates

/**
 * TODO
 * - Smarter AI
 * - Save country images and tint
 * - Refactor loop to handle higher/more granular speeds
 */

// Constants
final boolean MOVIE_MODE = true;
int NUM_PLAYERS = 10;
final int NUM_FACES = 6; // it's hip to be hex.
final int NUM_STARTING_DICE_PER_TEAM = 6;
final int MIN_CELLS_PER_COUNTRY = 6;
final int MAX_CELLS_PER_COUNTRY = 14;
final int DICE_SIDES = 6;
final int GRID_WIDTH = 58;
final int GRID_HEIGHT = 46;

// Grid Properties
float tileRadius = 10;
float hexRatio = 0.8457;
PVector gridPos; // the TOP-left corner of the grid.
Cell[][] gridCells;
Country[] countries=new Country[0];

// Game Loop
boolean isGameOver = false;
int currPlayerIndex;
boolean[] eliminated;
String currPlayerName;
boolean doHideBattleDice=false;
boolean isAIExecutingTurn;
AI[] botPlayers;
float timeWhenNextAIStep;
// Time Variables
float currTime; // in SECONDS.
float timeScale = 1; // how fast currTime advances is scaled by this.
int pmillis; // previous millis.

int turnCount;
int selectedCountryIndex;

boolean isBattleMode = false;
Country attackingCountry, defendingCountry;
int attackSum, defendSum;
float timeWhenStartedRolling;
float timeWhenStartNextGame;


// ======== SETUP ========
void setup() {
  colorMode(HSB);
  size(1024, 768);
  textAlign(CENTER, CENTER);
  // textFont(loadFont("AdobeDevanagari-Bold-48.vlw"));

  startNewGame();
}


// ======== DRAW ========
void draw() {
  background(102);
  
  // Update timeElapsed.
  currTime += (millis()-pmillis) * 0.001 * timeScale;
  pmillis = millis();
  
  if (MOVIE_MODE && isGameOver && currTime > timeWhenStartNextGame) {
    startNewGame();
  }
  
  // DRAW!
  drawGridCells();

  // ---- BATTLE MODE ----
  if (isBattleMode) {
    float beenRollingFor = currTime - timeWhenStartedRolling;
    if (beenRollingFor < 1) {
      rollBattleDice();
    }
    else if (beenRollingFor > 2.5) {
      isBattleMode = false;
      if (attackSum > defendSum) {
        moveIntoCountry(attackingCountry, defendingCountry);
      }
      else {
        attackingCountry.myDice = 1; // BONK!
        setSelectedCountryIndex(-1);
      }
    }
    if (!doHideBattleDice) {
      showBattleDice();
    }
  }

  if (isAIExecutingTurn) {
    if (currTime > timeWhenNextAIStep) {
      botPlayers[currPlayerIndex].executeNextStep();
    }
  }

  if (!MOVIE_MODE) {
    drawCurrentPlayerHeader();
  }
}

void drawGridCells() {
  pushMatrix();
  translate(gridPos.x, gridPos.y);

  for (int i=0; i<countries.length; i++) {
    if (i==selectedCountryIndex) { 
      continue;
    } // skip the raised-up country.
    countries[i].drawMyCellsShadow();
  }
  for (int i=0; i<countries.length; i++) {
    if (i==selectedCountryIndex) { 
      continue;
    } // skip the raised-up country.
    countries[i].drawMyCellsFill();
    countries[i].drawBorders();
  }

  // Draw raised-up country.
  if (selectedCountryIndex >= 0) {
    countries[selectedCountryIndex].drawMyCellsShadow();
    countries[selectedCountryIndex].drawMyCellsFill();
    countries[selectedCountryIndex].drawBorders();
  }

  popMatrix();
}

void drawCurrentPlayerHeader() {
  noStroke();
  fill(teamColor(currPlayerIndex));
  rect(0, 0, width, 40);
  fill(0);
  textSize(36);
  text(currPlayerName + "'s Turn", width/2, 20);
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

