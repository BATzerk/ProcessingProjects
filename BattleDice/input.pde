void endTurn() {
  currentPlayerIndex = (currentPlayerIndex + 1) % numOfPlayers;
  if (turnCount >= numOfPlayers) {
    for (int i = 0; i < countries.length; i++) {
      if (countries[i].myTeamIndex != currentPlayerIndex) {
        continue;
      }
      countries[i].myDice += 1;
      // TODO: Overflow full countries
    }
  }
  turnCount ++;
}

void keyPressed() {
  if (key == ' ') {
    remakeGridToGoodLayout();
  } else if (keyCode == ENTER) {
    endTurn();
  }
}

void moveIntoCountry(Country from, Country to) {
  to.myTeamIndex = currentPlayerIndex;
  int targetCapacity = to.cells.size();
  int diceToGive = from.myDice - 1;
  if (targetCapacity < diceToGive) {
    diceToGive = targetCapacity;
  }
  to.myDice = diceToGive;
  from.myDice -= diceToGive;
  selectedCountryIndex = -1;
}

void mousePressed() {
  Cell cellMouse = getPlayableCellByScreenPos(mouseX, mouseY);
  if (cellMouse == null) {
    selectedCountryIndex = -1;
    return;
  }

  Country country = cellMouse.myCountry;

  if (selectedCountryIndex == -1) {
    if (
      country.myTeamIndex == currentPlayerIndex &&
      country.myDice > 1
    ) {
      selectedCountryIndex = country.ID;
    }
  } else {
    Country selectedCountry = countries[selectedCountryIndex];
    // Switch country
    if (country.myTeamIndex == currentPlayerIndex) {
      selectedCountryIndex = country.ID;
      return;
    }

    boolean isNeighbor = selectedCountry.isNeighboring(country);
    if (!isNeighbor) {
      selectedCountryIndex = -1;
      return;
    }
    if (country.myTeamIndex == -1) {
      moveIntoCountry(selectedCountry, country);
    } else {
      setupBattle(selectedCountry, country);
    }
  }
}
