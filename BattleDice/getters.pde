

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

Country getCountryByScreenPos(float x, float y) {
  Cell cell = getPlayableCellByScreenPos(x, y);
  return cell == null ? null : cell.myCountry;
}

boolean canSelectCountry(Country country) {
  return country != null
    && country.myTeamIndex == currPlayerIndex
    && country.myDice > 1;
}

boolean canAttackCountry(Country attacker, Country defender) {
  return attacker != null
    && defender != null
    && attacker.ID != defender.ID
    && attacker.myDice > 1
    && attacker.myTeamIndex == currPlayerIndex
    && defender.myTeamIndex != currPlayerIndex
    && attacker.isNeighboring(defender);
}

float getWinChance(int attackDice, int defendDice) {
  if (defendDice <= 0 || attackDice > defendDice * DICE_SIDES) {
    return 1;
  }

  float[] attackOdds = getDiceSumOdds(attackDice);
  float[] defendOdds = getDiceSumOdds(defendDice);
  float chance = 0;
  for (int attackSum=0; attackSum<attackOdds.length; attackSum++) {
    if (attackOdds[attackSum] == 0) {
      continue;
    }
    for (int defendSum=0; defendSum<defendOdds.length && defendSum<attackSum; defendSum++) {
      chance += attackOdds[attackSum] * defendOdds[defendSum];
    }
  }
  return chance;
}

float[] getDiceSumOdds(int diceCount) {
  float[] odds = new float[diceCount * DICE_SIDES + 1];
  odds[0] = 1;
  for (int d=0; d<diceCount; d++) {
    float[] nextOdds = new float[diceCount * DICE_SIDES + 1];
    for (int sum=0; sum<odds.length; sum++) {
      if (odds[sum] == 0) {
        continue;
      }
      for (int roll=1; roll<=DICE_SIDES; roll++) {
        nextOdds[sum + roll] += odds[sum] / DICE_SIDES;
      }
    }
    odds = nextOdds;
  }
  return odds;
}

boolean canMigrateDice(Country from, Country _to) {
  return from != null
    && _to != null
    && from.ID != _to.ID
    && from.myDice > 1
    && from.myTeamIndex == currPlayerIndex
    && _to.myTeamIndex == currPlayerIndex
    && areCountriesInSameOwnedGroup(from, _to)
    && _to.myDice + from.myDice - 1 <= _to.cells.size();
}

boolean canActOnCountry(Country from, Country _to) {
  return canAttackCountry(from, _to) || canMigrateDice(from, _to);
}

boolean areCountriesInSameOwnedGroup(Country from, Country _to) {
  if (from == null || _to == null || from.myTeamIndex != _to.myTeamIndex) {
    return false;
  }

  int[] group = from.getMyCountryGroup();
  for (int i=0; i<group.length; i++) {
    if (group[i] == _to.ID) {
      return true;
    }
  }
  return false;
}

boolean isCountryInteractable(Country country) {
  if (!isCurrentPlayerHuman() || isBattleMode || isGameOver || country == null) {
    return false;
  }
  if (selectedCountryIndex == -1) {
    return canSelectCountry(country);
  }
  return canActOnCountry(countries[selectedCountryIndex], country);
}

boolean isCountryHovered(Country country) {
  if (!isCurrentPlayerHuman() || isBattleMode || isGameOver) {
    return false;
  }
  Country hovered = getCountryByScreenPos(mouseX, mouseY);
  return hovered != null && hovered.ID == country.ID;
}

boolean isCountryHoveredAndInteractable(Country country) {
  return isCountryHovered(country) && isCountryInteractable(country);
}

boolean shouldShowEndTurnButton() {
  return isCurrentPlayerHuman() && !isBattleMode && !isGameOver;
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
    if (countries[i].myTeamIndex > -1) {
      for (int c = 0; c < countries[i].neighbors.length; c++) {
        if (countries[i].neighbors[c].myTeamIndex > -1) {
          println("= Neighboring enemies");
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
  return (index * 255/NUM_PLAYERS + 65) % 255;
}
