

// Grid Properties
final int NUM_FACES = 6; // it's hip to be hex.
final int MIN_CELLS_PER_COUNTRY = 6;
final int MAX_CELLS_PER_COUNTRY = 14;
float tileRadius = 14;
float hexRatio = 0.8457;
PVector gridPos; // the TOP-left corner of the grid.
Cell[][] gridCells;
Country[] countries;

// Game Loop
int numOfPlayers = 4;
int currentPlayerIndex = 0;
int turnCount = 1;

int selectedCountryIndex = -1;

boolean rollingDice = false;
Country attackingCountry, defendingCountry;
int attackSum, defendSum;
int startedRolling;

// ======== SETUP ========
void setup() {
  colorMode(HSB);
  size(800, 600);
  textAlign(CENTER, CENTER);
  // textFont(loadFont("AdobeDevanagari-Bold-48.vlw"));

  remakeGridToGoodLayout();
}


// ======== DRAW ========
void draw() {
  background(240);

  drawGridCells();

  if (rollingDice) {
    int beenRollingFor = millis() - startedRolling;
    if (beenRollingFor < 500) {
      rollBattleDice();
    } else if (beenRollingFor > 3000) {
      rollingDice = false;
      if (attackSum > defendSum) {
        moveIntoCountry(attackingCountry, defendingCountry);
      } else {
        attackingCountry.myDice = 1; // BONK!
      }
    }
    showBattleDice();
  }

  noStroke();
  fill(teamColor(currentPlayerIndex));
  rect(0, 0, width, 40);
  fill(0);
  textSize(36);
  text("PLAYER: " + currentPlayerIndex, width/2, 20);
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
    countries[i].drawMyCells();
    countries[i].drawBorders();
  }

  // Draw raised-up country.
  if (selectedCountryIndex >= 0) {
    countries[selectedCountryIndex].drawMyCellsShadow();
    countries[selectedCountryIndex].drawMyCells();
    countries[selectedCountryIndex].drawBorders();
  }

  //  for (int i = 0; i < gridCells.length; i++) {
  //    for (int j = 0; j < gridCells[i].length; j++) {
  //      if (gridCells[i][j].myCountry != null) {
  //        gridCells[i][j].drawShadow();
  //      }
  //    }
  //  }
  //  for (int i = 0; i < gridCells.length; i++) {
  //    for (int j = 0; j < gridCells[i].length; j++) {
  //      if (gridCells[i][j].myCountry != null) {
  //        gridCells[i][j].draw();
  //      }
  //    }
  //  }


  popMatrix();
}

color teamColor(int index) {
  return color(teamHue(index), 122, 255);
}
float teamHue(int index) {
  return index * 255/numOfPlayers;
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
  //rotate(PI/2);
  beginShape();
  vertex(radius*hexRatio, radius*0.5);
  vertex(0, radius);
  vertex(-radius*hexRatio, radius*0.5);
  vertex(-radius*hexRatio, -radius*0.5);
  vertex(0, -radius);
  vertex( radius*hexRatio, -radius*0.5);
  vertex( radius*hexRatio, radius*0.5);
  endShape();
  //rotate(-PI/2);
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
