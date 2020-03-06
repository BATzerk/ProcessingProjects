import java.util.LinkedList;

class Country
{
  int ownedBy = -1;
  int numDice = 0;
  LinkedList<Cell> cells;
  LinkedList<Country> neighbors;
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

  void draw() {
  }
}

void growCountryStep() {
  for (int i = 0; i < countries.length; i++) {
    Cell newFriend;
    int limit = 100;
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

void keyPressed() {
  growCountryStep();
}
