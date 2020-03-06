

// Grid Properties
final int NUM_FACES = 6; // it's hip to be hex.
final int MIN_CELLS_PER_COUNTRY = 6;
float tileRadius = 14;
float hexRatio = 0.8457;
PVector gridPos; // the TOP-left corner of the grid.
Cell[][] gridCells;
Country[] countries;


// ======== SETUP ========
void setup() {
  colorMode(HSB);
  size(800, 600);

  remakeGridToGoodLayout();
}




// ======== DRAW ========
void draw() {
  background(240);

  drawGridCells();
}

void drawGridCells() {
  pushMatrix();
  translate(gridPos.x, gridPos.y);
  for (int i = 0; i < gridCells.length; i++) {
    for (int j = 0; j < gridCells[i].length; j++) {
      if (gridCells[i][j].myCountry != null) {
        gridCells[i][j].drawShadow();
      }
    }
  }
  for (int i = 0; i < gridCells.length; i++) {
    for (int j = 0; j < gridCells[i].length; j++) {
      if (gridCells[i][j].myCountry != null) {
        gridCells[i][j].draw();
      }
    }
  }

  for (int i = 0; i < countries.length; i++) {
    countries[i].draw();
  }
  popMatrix();
}

void drawHexagon(PVector pos) {
  drawHexagon(pos.x, pos.y);
}
void drawHexagon(float x, float y) {
  translate( x, y); // pushMatrix
  //rotate(PI/2);
  beginShape();
  vertex(tileRadius*hexRatio, tileRadius*0.5);
  vertex(0, tileRadius);
  vertex(-tileRadius*hexRatio, tileRadius*0.5);
  vertex(-tileRadius*hexRatio, -tileRadius*0.5);
  vertex(0, -tileRadius);
  vertex( tileRadius*hexRatio, -tileRadius*0.5);
  vertex( tileRadius*hexRatio, tileRadius*0.5);
  endShape();
  //rotate(-PI/2);
  translate(-x, -y); // popMatrix
}
void drawHexLine(Vector2Int gridPos, int face) {
  pushMatrix();
  translate(getScreenX(gridPos.x,gridPos.y), getScreenY(gridPos.y));
  switch (face) {
    case 0: line(0,-tileRadius,   tileRadius*hexRatio, -tileRadius*0.5); break;
    case 1: line( tileRadius*hexRatio, -tileRadius*0.5,   tileRadius*hexRatio, tileRadius*0.5); break;
    case 2: line(tileRadius*hexRatio, tileRadius*0.5, 0,tileRadius); break;
    case 3: line(0,tileRadius, -tileRadius*hexRatio, tileRadius*0.5); break;
    case 4: line(-tileRadius*hexRatio, tileRadius*0.5, -tileRadius*hexRatio, -tileRadius*0.5); break;
    case 5: line(-tileRadius*hexRatio, -tileRadius*0.5, 0,-tileRadius); break;
  }
  popMatrix();
}


void keyPressed() {
  if (key == ' ') {
    remakeGridToGoodLayout();
  }
  println(key);
}







