// HexDig
//  by Brett Taylor


float tileRadius = 52;
float hexRatio = 0.8457;

float gridX = 100; // the top-left position of the grid
float gridY = 100; // the top-left position of the grid

int cols,rows;
int mouseGridX,mouseGridY;
int pmouseGridX,pmouseGridY;

Card[] cards;
GridSpace[][] gridSpaces;


void setup() {
  size(800,600);
  colorMode(HSB);
  frameRate(50);
  smooth();
  
  resetGame();
}

void resetGame() {
  // Make gridSpaces!
  String[] boardLayout = boardLayouts[0];
  cols = int(boardLayout[0].length()*0.5);
  rows = boardLayout.length;
  gridSpaces = new GridSpace[cols][rows];
  int xOffset;
  String tempChar;
  for (int i=0; i<cols; i++) {
    for (int j=0; j<rows; j++) {
      xOffset = j%2==1 ? 0 : 1;
      tempChar = boardLayout[j].substring(xOffset+i*2,xOffset+i*2+1);
      gridSpaces[i][j] = new GridSpace(tempChar.equals("o"));
    }
  }
  
  // Add cards!
  cards = new Card[0];
  addCard(0);
  addCard(1);
  addCard(2);
}


void addCard(int footprintsIndex) {
  Card newCard = new Card(footprintsIndex);
  cards = (Card[]) append(cards, newCard);
  int count=0;
  int randCol = randomCol();
  int randRow = randomRow();
  while (count++<100 && !doesCardFitInLocation(randCol,randRow, newCard)) {
    randCol = randomCol();
    randRow = randomRow();
  }
  newCard.setColAndRow(randCol,randRow);
}

int randomCol() { return int(random(cols)); }
int randomRow() { return int(random(rows)); }


void addCardToItsGridSpaces(Card card) {
  for (int i=0; i<card.footprints.length; i++) {
    println(card.footprints[i].x + "  " + card.footprints[i].y);
    gridSpaces[card.col+card.footprints[i].x][card.row+card.footprints[i].y].myCard = card;
  }
}
void removeCardFromItsGridSpaces(Card card) {
  for (int i=0; i<card.footprints.length; i++) {
    if (gridSpaces[card.col+card.footprints[i].x][card.row+card.footprints[i].y].myCard == card) {
      gridSpaces[card.col+card.footprints[i].x][card.row+card.footprints[i].y].myCard = null;
    }
  }
}



void draw() {
  background(64);
  
  // determine what space the mouse is in
  mouseGridX = int((mouseX-gridX) / tileRadius * 2/3);
  mouseGridY = int((mouseY-gridY+tileRadius*0.5) / tileRadius * 2/3);
  if (mouseGridX!=pmouseGridX || mouseGridY!=pmouseGridY) {
    //if (doesCardFitInLocation(mouseGridX,mouseGridY, cards[0])) {
    //  cards[0].setColAndRow(mouseGridX,mouseGridY);
    //}
  }
  pmouseGridX = mouseGridX;
  pmouseGridY = mouseGridY;
  
  
  textAlign(CENTER, CENTER);
  textSize(40);
  
  // draw grid
  pushMatrix();
  //translate(width*0.5, height*0.5);
  translate(gridX,gridY);
  stroke(0, 100);
  fill(255, 200);
  float xOffset = 0;
  for (int i=0; i<cols; i++) {
    for (int j=0; j<rows; j++) {
      if (gridSpaces[i][j].isPlayableSpace) {
        fill(60, 200);
        drawHexagon(getX(i,j), getY(j));
        fill(0, 100);
        //text(i + " " + j, getX(i,j), getY(j));
      }
    }
  }
  
  // draw cards!
  for (int i=0; i<cards.length; i++) {
    cards[i].draw();
  }
  
  // draw covers!
  fill(200);
  stroke(100);
  strokeWeight(3);
  for (int i=0; i<cols; i++) {
    for (int j=0; j<rows; j++) {
      if (gridSpaces[i][j].isPlayableSpace && !gridSpaces[i][j].isRevealed) {
        drawHexagon(getX(i,j), getY(j));
      }
    }
  }
  
  // Highlight the space my mouse is over!
  fill(255, 100);
  stroke(255, 160);
  strokeWeight(3);
  drawHexagon(getX(mouseGridX,mouseGridY),getY(mouseGridY));
  
  popMatrix();
}



void drawHexagon(float X,float Y) {
  translate( X, Y); // pushMatrix
  //rotate(PI/2);
  beginShape();
  vertex(tileRadius*hexRatio, tileRadius*0.5);
  vertex(0, tileRadius);
  vertex(-tileRadius*hexRatio, tileRadius*0.5);
  vertex(-tileRadius*hexRatio,-tileRadius*0.5);
  vertex(0, -tileRadius);
  vertex( tileRadius*hexRatio,-tileRadius*0.5);
  vertex( tileRadius*hexRatio, tileRadius*0.5);
  /*
  vertex( tileRadius*0.5, tileRadius*hexRatio);
  vertex( tileRadius, 0);
  vertex( tileRadius*0.5, -tileRadius*hexRatio);
  vertex(-tileRadius*0.5, -tileRadius*hexRatio);
  vertex(-tileRadius, 0);
  vertex(-tileRadius*0.5, tileRadius*hexRatio);
  vertex( tileRadius*0.5, tileRadius*hexRatio);
  //*/
  endShape();
  //rotate(-PI/2);
  translate(-X,-Y); // popMatrix
}


void revealSpaceAt(int col,int row) {
  getGridSpaceAt(col,row).isRevealed = true;
}



float getX(float col,float row) {
  float xOffset = 0;
  if (row%2==0) xOffset = tileRadius*hexRatio;
  return col*tileRadius*2*hexRatio + xOffset;
}
float getY(float row) {
  return row*(tileRadius*3/2);
}


void mousePressed() {
  if (getGridSpaceAt(mouseGridX,mouseGridY)!=null && getGridSpaceAt(mouseGridX,mouseGridY).isPlayableSpace && !getGridSpaceAt(mouseGridX,mouseGridY).isRevealed) {
    revealSpaceAt(mouseGridX,mouseGridY);
  }
}

void keyPressed() {
  if (keyCode == ENTER) {
    resetGame();
  }
}









