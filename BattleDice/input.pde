

void keyPressed() {
  if (key == ' ') {
    startNewGame();
  }
  else if (keyCode == ENTER) {
    endTurn();
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
      country.myDice > 1                           // can't attack with only 1 die
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
    if (country.myTeamIndex == -1) { // take empty countries
      moveIntoCountry(selectedCountry, country);
    } else { // fight occupied countries
      setupBattle(selectedCountry, country);
    }
  }
}
