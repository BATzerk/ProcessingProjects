import java.util.LinkedList;
import java.util.HashSet;
import java.util.Set;

class Country
{
  int myTeamIndex = -1;
  int numDice = 1;
  LinkedList<Cell> cells;
  Country[] neighbors;
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
  
  boolean isNeighboring(Country op) {
    return isNeighboring(op.ID);
  }
  boolean isNeighboring(int id) {
    if (id < 0) return false;
    for (int i = 0; i < neighbors.length; i++) {
      if (neighbors[i].ID == id) {
        return true;
      }
    }
    return false;
  }

  void learnNeighbors() {
    Set<Integer> set = new HashSet<Integer>();
    for (int i = 0; i < cells.size (); i++) {
      for (int face = 0; face < NUM_FACES; face++) {
        Cell ncell = cells.get(i).getNeighbor(face);
        if (ncell != null && ncell.myCountry != null) {
          set.add(ncell.myCountry.ID);
        }
      }
    }
    set.remove(this.ID);
    this.neighbors = new Country[set.size()];
    int i = 0;
    for (int id : set) {
      neighbors[i] = countries[id];
      i++;
    }
  }
  
  void addNeighborsToSet(Set ids, Set checked) {
    checked.add(this.ID);
    ids.add(this.ID);
    for (int i = 0; i < this.neighbors.length; i++) {
      ids.add(this.neighbors[i].ID);
      if (!checked.contains(this.neighbors[i].ID)) {
        this.neighbors[i].addNeighborsToSet(ids, checked);
      }
    }
  }
  
  int countCountriesOnIsland() {
    Set<Integer> ids = new HashSet<Integer>();
    Set<Integer> checked = new HashSet<Integer>();
    this.addNeighborsToSet(ids, checked);
    return ids.size();
  }
  
  color myColor() {
    boolean isInDanger = selectedCountryIndex != this.ID && isNeighboring(selectedCountryIndex);
     
    if (myTeamIndex > -1) {
      return isInDanger
        ? color(myTeamIndex * 255/numOfPlayers, 70, 255)
        : color(myTeamIndex * 255/numOfPlayers, 122, 255);
    }
     return isInDanger ? color(255) : color(32, 34, 234);
  }

  void drawMyCells() {
    displayOffsetY = selectedCountryIndex==ID ? -8 : 0;

    pushMatrix();
    translate(0, displayOffsetY);
    fill(myColor());
    for (int i=0; i<cells.size (); i++) {
      Cell cell = (Cell) cells.get(i);
      cell.draw();
    }
    popMatrix();
  }
  void drawMyCellsShadow() {
    pushMatrix();
    translate(0, displayOffsetY);
    for (int i=0; i<cells.size (); i++) {
      Cell cell = (Cell) cells.get(i);
      cell.drawShadow();
    }
    popMatrix();
  }
  void drawBorders() {
    pushMatrix();
    translate(0, displayOffsetY);
    for (int i=0; i<cells.size (); i++) {
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

