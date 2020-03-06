Cell[][] gridCells;

void setup() {
  gridCells = new Cell[10][10];
  for (int i = 0; i < gridCells.length; i++) {
    for (int j = 0; j < gridCells[i].length; j++) {
      gridCells[i][j] = new Cell(i, j);
    }
  }

  println(gridCells[1][1].neighbor(0).gridPos); // 1, 0
  println(gridCells[1][2].neighbor(0).gridPos); // 2, 1
}

void draw() {
}
