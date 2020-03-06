

Cell getCell(Vector2Int pos) {
  return getCell(pos.x, pos.y);
}
Cell getCell(int col, int row) {
  if (col<0 || row<0  ||  col>=gridCells.length || row >= gridCells[col].length) {
    return null;
  }
  return gridCells[col][row];
}
Cell getRandomCell() {
  Cell ret;
  do {
    ret = getCell(floor(random(10)), floor(random(10)));
  } while (ret == null);
  return ret;
}

float getScreenX(float col, float row) {
  float xOffset = 0;
  if (row%2==0) xOffset = tileRadius*hexRatio;
  return col*tileRadius*2*hexRatio + xOffset;
}
float getScreenY(float row) {
  return row*(tileRadius*3/2);
}

public Vector2Int getOffsetFromFace(int row, int face) {
  if (row % 2 == 0) {
    // Even rows
    switch (face) {
    case 0: 
      return new Vector2Int(1, -1);
    case 1: 
      return new Vector2Int(1, 0);
    case 2: 
      return new Vector2Int(1, 1);
    case 3: 
      return new Vector2Int(0, 1);
    case 4: 
      return new Vector2Int(-1, 0);
    case 5: 
      return new Vector2Int(0, -1);
    }
  }
  // Odd rows
  switch (face) {
  case 0: 
    return new Vector2Int(0, -1);
  case 1: 
    return new Vector2Int(1, 0);
  case 2: 
    return new Vector2Int(0, 1);
  case 3: 
    return new Vector2Int(-1, 1);
  case 4: 
    return new Vector2Int(-1, 0);
  case 5: 
    return new Vector2Int(-1, -1);
  }
  throw new Error("BAD FACE");
}