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

  if (selectedCountryIndex == -1) { // If no country selected
    if (
      country.myTeamIndex == currentPlayerIndex && // players can only select THEIR countries
      country.myDice > 1                           // can't attack with only 1 die
    ) {
      selectedCountryIndex = country.ID;
    }
  } else { // Clicking second country (already have selection)
    Country selectedCountry = countries[selectedCountryIndex];

    if (country.myTeamIndex == currentPlayerIndex) { // another of player's countries?
      selectedCountryIndex = country.ID; // switch
      return;
    }

    boolean isNeighbor = selectedCountry.isNeighboring(country);
    if (!isNeighbor) { // clicking away to relo-- deselect
      selectedCountryIndex = -1;
      return;
    }
    if (country.myTeamIndex == -1) { // take empty countries
      moveIntoCountry(selectedCountry, country);
    } else { // fight occupied countries
      setupBattle(selectedCountry, country);
    }
  }
}
