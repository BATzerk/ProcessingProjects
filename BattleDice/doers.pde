



void remakeGridToGoodLayout() {
  int i=0;
  for (i=0; i<=50; i++) { // try a bunch of times.
    remakeGridTotallyRandomly();
    if (isCurrentGridLayoutGood()) { break; } 
    if (i>=20) {
      println("Error! Could not find good layout. Oh well, going with this one.");
    }
  }
//  println("Tried times: " + i);
}

void remakeGridTotallyRandomly() {
  int cols = 30;
  int rows = 22;
  float gw = cols * tileRadius * 2/3 * sqrt(6);
  float gh = rows * tileRadius * 1.4;
  
  // Cells
  gridCells = new Cell[cols][rows];
  for (int i = 0; i < gridCells.length; i++) {
    for (int j = 0; j < gridCells[i].length; j++) {
      gridCells[i][j] = new Cell(i, j);
    }
  }
  
  gridPos = new PVector((width - gw) / 2, (height - gh) / 2);
  
  // Countries
  int numCountries = cols * rows / 18;
  countries = new Country[numCountries];
  for (int i = 0; i < countries.length; i++) {
    countries[i] = new Country(i, getRandomCell());
  }
  for (int i = 0; i < 100; i++) {
    growCountryStep();
  }
}
