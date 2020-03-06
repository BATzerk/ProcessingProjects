// c_Card


class Card {
  int col,row;
  Point[] footprints;
  Point[] footprintsE;
  Point[] footprintsO;
  float xDisplay,yDisplay;
  float myHue;
  
  Card(int footprintsStringIndex) {
    myHue = 10 + footprintsStringIndex*70;
    String[] footprintsString = cardLayouts[footprintsStringIndex];
    
    footprintsE = new Point[0];
    footprintsO = new Point[0];
    
    int cols = int(footprintsString[0].length()*0.5);
    int rows = footprintsString.length;
    int xOffset;
    String tempChar;
    for (int i=0; i<cols; i++) {
      for (int j=0; j<rows; j++) {
        xOffset = j%2==1 ? 0 : 1;
        tempChar = footprintsString[j].substring(xOffset+i*2,xOffset+i*2+1);
        if (tempChar.equals("o")) {
          footprintsE = (Point[]) append(footprintsE, new Point(i,j));
          footprintsO = (Point[]) append(footprintsO, new Point(i,j));
        }
      }
    }
    // Offset the odd footprints
    for (int i=0; i<footprintsO.length; i++) {
      if (footprintsO[i].y%2==1) footprintsO[i].x -= 1;
    }
    updateFootprints();
  }
  void updateFootprints() {
    if (row%2==0) footprints = footprintsE;
    else footprints = footprintsO;
  }
  void setColAndRow(int Col,int Row) {
    removeCardFromItsGridSpaces(this);
    col = Col;
    row = Row;
    updateFootprints();
    addCardToItsGridSpaces(this);
    
    //xDisplay = getXFromCol(col);
    //yDisplay = getYFromRow(row);
  }
  
  void draw() {
    fill(myHue,255,255, 180);
    stroke(myHue,255,180);
    strokeWeight(2);
    for (int i=0; i<footprints.length; i++) {
      drawHexagon(getX(col+footprints[i].x,row+footprints[i].y),getY(row+footprints[i].y));
    }
    
  }
  
}



