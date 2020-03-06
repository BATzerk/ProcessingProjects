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

  Country(int index, Cell startingCell) {
    cells = new LinkedList<Cell>();
    this.addCell(startingCell);
    ID = index;
  }

  void addCell(Cell c) {
    c.setCountry(this);
    cells.add(c);
  }

  Cell getRandomEdgeCell() {
    return cells.get(floor(random(cells.size())));
  }
  
  void learnNeighbors() {
    Set<Integer> set = new HashSet<Integer>();
    for (int i = 0; i < cells.size(); i++) {
      for (int face = 0; face < NUM_FACES; face++) {
        Cell ncell = cells.get(i).getNeighbor(face);
        if (ncell != null && ncell.myCountry != null) {
          set.add(ncell.myCountry.ID);
        }
      }
    }
    this.neighbors = new Country[set.size()];
    int i = 0;
    for (int id : set) {
      neighbors[i] = countries[id];
      i++;
    }
  }

  void draw() {
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
  }
}

void growCountryStep() {
  int maxNumCells = 14;
  for (int i = 0; i < countries.length; i++) {
    if (countries[i].cells.size() == maxNumCells) {
      continue;
    }
    Cell newFriend;
    int limit = 2;
    do {
      Cell edge = countries[i].getRandomEdgeCell();
      int face = floor(random(6));
      newFriend = edge.getNeighbor(face);
      limit --;
    } while (limit > 0 && (newFriend == null || newFriend.myCountry != null));

    if (limit > 0) {
      countries[i].addCell(newFriend);
    }
  }
}
