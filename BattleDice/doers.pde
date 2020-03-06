



void remakeGrid() {
  int cols = 20;
  int rows = 14;
  // Cells
  gridCells = new Cell[cols][rows];
  for (int i = 0; i < gridCells.length; i++) {
    for (int j = 0; j < gridCells[i].length; j++) {
      gridCells[i][j] = new Cell(i, j);
    }
  }
  
  float gw = cols * tileRadius * 2/3 * sqrt(6);
  float gh = rows * tileRadius * 1.4;
  print(gh);
  gridPos = new PVector((width - gw) / 2, (height - gh) / 2);
  
  // Countries
  int numCountries = cols * rows / 12;
  countries = new Country[numCountries];
  for (int i = 0; i < countries.length; i++) {
    countries[i] = new Country(i, getRandomCell());
  }
  for (int i = 0; i < 100; i++) {
    growCountryStep();
  }
  
  // Learn neighbors
  for (int i = 0; i < countries.length; i++) {
    countries[i].learnNeighbors();
  }
}
