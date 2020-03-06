import java.util.LinkedList;

class Country
{
  int myTeamIndex = -1;
  int numDice = 1;
  LinkedList<Cell> cells;
  LinkedList<Country> neighbors;
  int ID;
  float displayOffsetY; // for raising up the selected country.

  Country(int index, Cell startingCell) {
    this.ID = index;
    this.cells = new LinkedList<Cell>();
    this.addCell(startingCell);
  }

  void addCell(Cell c) {
    c.setCountry(this);
    cells.add(c);
  }

  Cell getRandomEdgeCell() {
    return cells.get(floor(random(cells.size())));
  }
  
  void drawMyCells() {
    displayOffsetY = selectedCountryIndex==ID ? -8 : 0;
    
    pushMatrix();
    translate(0, displayOffsetY);
    for (int i=0; i<cells.size(); i++) {
      Cell cell = (Cell) cells.get(i);
      cell.draw();
    }
    popMatrix();
  }
  void drawMyCellsShadow() {
    pushMatrix();
    translate(0, displayOffsetY);
    for (int i=0; i<cells.size(); i++) {
      Cell cell = (Cell) cells.get(i);
      cell.drawShadow();
    }
    popMatrix();
  }
  void drawBorders() {
    pushMatrix();
    translate(0, displayOffsetY);
    for (int i=0; i<cells.size(); i++) {
      Cell thisCell = (Cell) cells.get(i);
      for (int face=0; face<NUM_FACES; face++) {
        Cell otherCell = thisCell.getNeighbor(face);
        boolean isBorder = otherCell==null || thisCell.myCountry!=otherCell.myCountry;
        if (isBorder) {
          stroke(80);
          strokeWeight(3.5);
          drawHexLine(thisCell.gridPos, face);
        }
      }
    }
    popMatrix();
  }
}

