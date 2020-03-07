

float sinRange(float val, float min,float max) {
  return map(sin(val), -1,1, min,max);
}
Cell getCell(Vector2Int pos) {
  return getCell(pos.x, pos.y);
}
Cell getCell(int col, int row) {
  if (col<0 || row<0  ||  col>=gridCells.length || row >= gridCells[col].length) {
    return null;
  }
  return gridCells[col][row];
}
Cell getRandomEmptyCell() {
  Cell ret;
  do {
    ret = getCell(floor(random(gridCells.length)), floor(random(gridCells[0].length)));
  } while (ret == null || ret.myCountry != null);
  return ret;
}

Cell getPlayableCellByScreenPos(float x, float y) {
  int mouseRow = round((y - gridPos.y) / (tileRadius * 3/2));
  float xOffset = mouseRow % 2 == 0
    ? xOffset = tileRadius*hexRatio
    : 0;
  int mouseCol = round((x - gridPos.x - xOffset) / (tileRadius * 2 * hexRatio));
  Cell cell = getCell(mouseCol, mouseRow);
  if (cell == null || cell.myCountry == null) { return null; } // No country? Not playable.
  return cell;
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

boolean isCurrentGridLayoutGood() {
  // Any countries that're TOO small??
  for (int i=0; i<countries.length; i++) {
    if (countries[i].cells.size() < MIN_CELLS_PER_COUNTRY) { return false; }
  }

  // Are all the countries NOT on the same island? Return false.
  if (countries.length > countries[0].countCountriesOnIsland()) {
    return false;
  }

  // Looks good!
  return true;
}

String getPlayerName(int playerIndex) {
  switch (playerIndex) {
    case 0: return "RED";
    case 1: return "GREEN";
    case 2: return "BLUE";
    case 3: return "INDIGO";
    default: return "UNDEFINED";
  }
}
color teamColor(int index, int alpha) {
  return color(teamHue(index), 122, 255, alpha);
}
color teamColor(int index) {
  return teamColor(index, 255);
}
float teamHue(int index) {
  return index * 255/numOfPlayers;
}

color lerpColorHSB(color a, color b, float perc) {
  float hu = lerp(hue(a), hue(b), perc);
  float sa = lerp(saturation(a), saturation(b), perc);
  float br = lerp(brightness(a), brightness(b), perc);
  float al = lerp(alpha(a), alpha(b), perc);
  return color(hu, sa, br, al);
}
