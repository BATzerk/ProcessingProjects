

// Grid Properties
float tileRadius = 30;
float hexRatio = 0.8457;
PVector gridPos; // the TOP-left corner of the grid.
Cell[][] gridCells;
Country[] countries;


// ======== SETUP ========
void setup() {
  colorMode(HSB);
  size(800, 600);

  remakeGrid();
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
      gridCells[i][j].draw();
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


void keyPressed() {
  if (key == ' ') {
    remakeGrid();
  }
  println(key);
}
