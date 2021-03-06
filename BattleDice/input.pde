

void keyPressed() {
  if (key == 'r') {
    startNewGame();
  }
  else if (key == 'd') {
    doHideBattleDice = !doHideBattleDice;
  }
  else if (key == 'a') {
    if (botPlayers[currPlayerIndex] == null) {
      botPlayers[currPlayerIndex] = new AI(currPlayerIndex);
      botPlayers[currPlayerIndex].executeNextStep();
    } else {
      isAIExecutingTurn = false;
      botPlayers[currPlayerIndex] = null;
    }
  }
  else if (key == 't') {
    timeScale = timeScale>1 ? 1 : 1000;
  }
  else if (keyCode == ENTER) {
    startNextPlayerTurn();
  }
}


void mousePressed() {
  Cell cellMouse = getPlayableCellByScreenPos(mouseX, mouseY);
  if (cellMouse == null) {
    setSelectedCountryIndex(-1);
    return;
  }

  Country country = cellMouse.myCountry;

  if (selectedCountryIndex == -1) { // If no country selected
    if (
      country.myTeamIndex == currPlayerIndex && // players can only select THEIR countries
      country.myDice > 1                        // can't attack with only 1 die
    ) {
      setSelectedCountryIndex(country.ID);
    }
  } else { // Clicking second country (already have selection)
    Country selectedCountry = countries[selectedCountryIndex];

    if (country.myTeamIndex == currPlayerIndex) { // another of player's countries?
      setSelectedCountryIndex(country.ID); // switch
      return;
    }

    boolean isNeighbor = selectedCountry.isNeighboring(country);
    if (!isNeighbor) { // clicking away to relo-- deselect
      setSelectedCountryIndex(-1);
      return;
    }
    countryAttackOther(selectedCountry, country);
  }
}
