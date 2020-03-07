import java.util.LinkedList;
import java.util.HashSet;
import java.util.Set;

class Country
{
  int myTeamIndex = -1;
  int myDice = 0;
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
    if (id < 0 || id == this.ID) return false;
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

  void findNeighborsInGroup(Set ids, Set checked) {
    checked.add(this.ID);
    ids.add(this.ID);
    for (int i = 0; i < this.neighbors.length; i++) {
      if (this.neighbors[i].myTeamIndex != this.myTeamIndex) {
        continue;
      }
      ids.add(this.neighbors[i].ID);
      if (!checked.contains(this.neighbors[i].ID)) {
        this.neighbors[i].findNeighborsInGroup(ids, checked);
      }
    }
  }

  int[] getMyCountryGroup() {
    Set<Integer> ids = new HashSet<Integer>();
    Set<Integer> checked = new HashSet<Integer>();
    this.findNeighborsInGroup(ids, checked);
    int[] ret = new int[ids.size()];
    int i = 0;
    for (int id: ids) {
      ret[i++] = id;
    }
    return ret;
  }

  color myColor() {
    boolean isInDanger =
      selectedCountryIndex > -1
      && countries[selectedCountryIndex].myTeamIndex != this.myTeamIndex
      && isNeighboring(selectedCountryIndex);

    if (myTeamIndex > -1) {
      return isInDanger
        ? color(teamHue(myTeamIndex), 70, 255)
        : teamColor(myTeamIndex);
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
      if (i < myDice) {
        fill(255);
        drawHexagon(cell.screenPos, tileRadius / 2);
        fill(myColor());
      }
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

ArrayList<int[]> getCountryGroups() {
  Set<Integer> counted = new HashSet<Integer>();
  ArrayList<int[]> groupList = new ArrayList<int[]>();
  for (int i = 0; i < countries.length; i++) {
    if (!counted.contains(i)) {
      int[] group = countries[i].getMyCountryGroup();
      for (int j = 0; j < group.length; j++) {
        counted.add(group[j]);
      }
      groupList.add(group);
    }
  }
  return groupList;
}
