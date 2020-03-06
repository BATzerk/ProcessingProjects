static class Vector2Int {
  int x, y;
  Vector2Int (int x, int y) {
    this.x = x;
    this.y = y;
  }

  void add(Vector2Int op) {
    x += op.x;
    y += op.y;
  }

  static Vector2Int add(Vector2Int a, Vector2Int b) {
    return new Vector2Int(a.x + b.x, a.y + b.y);
  }
  
  public String toString() {
    return this.x + ", " + this.y;
  }
}

class Cell
{
  Vector2Int gridPos;

  Cell(int col, int row) {
    gridPos = new Vector2Int(col, row);
  }

  Cell neighbor(int face) {
    Vector2Int offset = getMyOffsetFromFace(face);
    offset.add(this.gridPos);
    return gridCells[offset.x][offset.y];
  }
  Vector2Int getMyOffsetFromFace(int face) {
    return getOffsetFromFace(gridPos.y, face);
  }
}

public Vector2Int getOffsetFromFace(int row, int face) {
  int colOffset = 1 - row % 2;
  switch (face) {
  case 0: 
    return new Vector2Int(colOffset, -1);
  case 1: 
    return new Vector2Int(1, 0);
  case 2: 
    return new Vector2Int(colOffset, 1);
  case 3: 
    return new Vector2Int(-colOffset, 1);
  case 4: 
    return new Vector2Int(-1, 0);
  case 5: 
    return new Vector2Int(-colOffset, -1);
  }
  throw new Error("BAD FACE");
}
