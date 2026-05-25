

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
  boolean shouldUseCell = false;
  int numAttemptsLeft = 100;
  do {
    ret = getCell(floor(random(gridCells.length)), floor(random(gridCells[0].length)));
    shouldUseCell = canGenerateLandAt(ret);
    numAttemptsLeft--;
  } while (numAttemptsLeft > 0 && !shouldUseCell);
  if (shouldUseCell) {
    return ret;
  }
  while (ret == null || ret.myCountry != null) {
    ret = getCell(floor(random(gridCells.length)), floor(random(gridCells[0].length)));
  }
  return ret;
}

boolean canGenerateLandAt(Cell cell) {
  if (cell == null || cell.myCountry != null) {
    return false;
  }
  return random(1) < getLandGenerationChance(cell);
}

float getLandGenerationChance(Cell cell) {
  int distanceFromEdge = min(
    min(cell.gridPos.x, GRID_WIDTH - 1 - cell.gridPos.x),
    min(cell.gridPos.y, GRID_HEIGHT - 1 - cell.gridPos.y)
  );
  int stepsNearEdge = EDGE_LAND_AVOIDANCE_DISTANCE - distanceFromEdge;
  if (stepsNearEdge <= 0) {
    return 1;
  }
  return pow(EDGE_LAND_GENERATION_CHANCE_PER_STEP, stepsNearEdge);
}

boolean canCountryHoldStartingDice(Country country) {
  return country.cells.size() >= NUM_STARTING_DICE_PER_TEAM;
}

int getCountryDistance(Country from, Country _to) {
  if (from == null || _to == null) {
    return Integer.MAX_VALUE;
  }
  if (from.ID == _to.ID) {
    return 0;
  }

  Set<Integer> visited = new HashSet<Integer>();
  ArrayList<Country> frontier = new ArrayList<Country>();
  frontier.add(from);
  visited.add(from.ID);
  int distance = 0;

  while (frontier.size() > 0) {
    ArrayList<Country> nextFrontier = new ArrayList<Country>();
    distance++;
    for (int i=0; i<frontier.size(); i++) {
      Country country = frontier.get(i);
      for (int n=0; n<country.neighbors.length; n++) {
        Country neighbor = country.neighbors[n];
        if (neighbor.ID == _to.ID) {
          return distance;
        }
        if (!visited.contains(neighbor.ID)) {
          visited.add(neighbor.ID);
          nextFrontier.add(neighbor);
        }
      }
    }
    frontier = nextFrontier;
  }

  return Integer.MAX_VALUE;
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

Country getCountryByScreenPos(float x, float y) {
  Cell cell = getPlayableCellByScreenPos(x, y);
  return cell == null ? null : cell.myCountry;
}

boolean isCountryInteractable(Country country) {
  if (!isCurrentPlayerHuman() || isBattleMode() || isMigrationMode() || isGameOver() || country == null) {
    return false;
  }
  if (selectedCountryIndex == NO_COUNTRY) {
    return canSelectCountry(country);
  }
  return canActOnCountry(countries[selectedCountryIndex], country);
}

boolean isCountryHovered(Country country) {
  if (!isCurrentPlayerHuman() || isBattleMode() || isMigrationMode() || isGameOver()) {
    return false;
  }
  Country hovered = getCountryByScreenPos(mouseX, mouseY);
  return hovered != null && hovered.ID == country.ID;
}

boolean isCountryHoveredAndInteractable(Country country) {
  return isCountryHovered(country) && isCountryInteractable(country);
}

boolean shouldShowEndTurnButton() {
  return isCurrentPlayerHuman() && !isBattleMode() && !isMigrationMode() && !isGameOver();
}

float getEndTurnButtonX() {
  return width - END_TURN_BUTTON_WIDTH - END_TURN_BUTTON_MARGIN;
}

float getEndTurnButtonY() {
  return height - END_TURN_BUTTON_HEIGHT - END_TURN_BUTTON_MARGIN - 34;
}

boolean isMouseOverEndTurnButton() {
  if (!shouldShowEndTurnButton()) {
    return false;
  }

  float x = getEndTurnButtonX();
  float y = getEndTurnButtonY();
  return mouseX >= x
    && mouseX <= x + END_TURN_BUTTON_WIDTH
    && mouseY >= y
    && mouseY <= y + END_TURN_BUTTON_HEIGHT;
}

boolean currentPlayerHasAvailableMove() {
  for (int i=0; i<countries.length; i++) {
    Country attacker = countries[i];
    if (!canSelectCountry(attacker)) {
      continue;
    }
    for (int n=0; n<countries.length; n++) {
      if (canActOnCountry(attacker, countries[n])) {
        return true;
      }
    }
  }
  return false;
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

enum Quality { IMPOSSIBLE, GOOD, BAD };
Quality isCurrentGridLayoutGood() {
  // Are all the countries NOT on the same island? Return false.
  if (countries.length > countries[0].countCountriesOnIsland()) {
    println("= More than one island");
    return Quality.IMPOSSIBLE;
  }

  // Any countries that're TOO small??
  for (int i=0; i<countries.length; i++) {
    if (countries[i].cells.size() < MIN_CELLS_PER_COUNTRY) {
      println("= Country too small");
      return Quality.BAD;
    }
  }

  // Neighboring enemies
  for (int i=0; i<countries.length; i++) {
    if (countries[i].myTeamIndex != NO_TEAM) {
      if (!canCountryHoldStartingDice(countries[i])) {
        println("= Starting country too small");
        return Quality.BAD;
      }
      for (int c = i + 1; c < countries.length; c++) {
        if (
          countries[c].myTeamIndex != NO_TEAM
          && getCountryDistance(countries[i], countries[c]) < STARTING_COUNTRY_MIN_DISTANCE
        ) {
          println("= Starting countries too close");
          return Quality.BAD;
        }
      }
    }
  }

  // Looks good!
  return Quality.GOOD;
}

String getPlayerName(int playerIndex) {
  switch (playerIndex) {
    case 0: return "GREEN";
    case 1: return "BLUE";
    case 2: return "INDIGO";
    case 3: return "RED";
    default: return "PLAYER " + (playerIndex + 1);
  }
}
int getPlayerDiceTotal(int playerIndex) {
  int total = 0;
  for (int i = 0; i < countries.length; i++) {
    if (countries[i].myTeamIndex == playerIndex) {
      total += countries[i].myDice;
    }
  }
  return total;
}
color teamColor(int index, int alpha) {
  return color(teamHue(index), 122, 255, alpha);
}
color teamColor(int index) {
  return teamColor(index, 255);
}
float teamHue(int index) {
  return (index * 255/playerCount + 65) % 255;
}
