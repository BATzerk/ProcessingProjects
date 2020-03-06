



void remakeGrid() {
  // Cells
  gridCells = new Cell[13][11];
  for (int i = 0; i < gridCells.length; i++) {
    for (int j = 0; j < gridCells[i].length; j++) {
      gridCells[i][j] = new Cell(i, j);
    }
  }
  
  float gw = gridCells.length * tileRadius * 2/3 * sqrt(6);
  float gh = gridCells[0].length * tileRadius * 1.4;
  print(gh);
  gridPos = new PVector((width - gw) / 2, (height - gh) / 2);
  
  // Countries
  countries = new Country[10];
  for (int i = 0; i < countries.length; i++) {
    countries[i] = new Country(i, getRandomCell());
  }
  for (int i = 0; i < 100; i++) {
    growCountryStep();
  }
}
