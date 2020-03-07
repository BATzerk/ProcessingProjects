

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
    selectedCountryIndex = -1;
    return;
  }

  Country country = cellMouse.myCountry;

  if (selectedCountryIndex == -1) {
    if (
      country.myTeamIndex == currPlayerIndex &&
      country.myDice > 1
    ) {
      selectedCountryIndex = country.ID;
    }
  } else {
    Country selectedCountry = countries[selectedCountryIndex];
    // Switch country
    if (country.myTeamIndex == currPlayerIndex) {
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
