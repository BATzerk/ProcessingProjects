class Cell
{
  // Properties
  Vector2Int gridPos;
  PVector screenPos;
  
  
  // ==== CONSTRUCTOR ====
  Cell(int col, int row) {
    gridPos = new Vector2Int(col, row);
    screenPos = new PVector(getScreenX(col,row), getScreenY(row));
  }

  // ==== GETTERS ====
  Cell neighbor(int face) {
    Vector2Int neighborPos = getMyOffsetFromFace(face);
    neighborPos.add(this.gridPos);
    return getCell(neighborPos);
  }
  Vector2Int getMyOffsetFromFace(int face) {
    return getOffsetFromFace(gridPos.y, face);
  }
  
  
  
  // ==== DRAW ====
  public void draw() {
    fill(100);
    stroke(70);
    strokeWeight(1);
    drawHexagon(screenPos);
  }
  
}

