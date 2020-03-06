void mousePressed() {
  Cell cellMouse = getPlayableCellByScreenPos(mouseX, mouseY);
  if (cellMouse == null) {
    selectedCountryIndex = -1;
    return;
  }
  
  Country country = cellMouse.myCountry;

  if (selectedCountryIndex == -1) {
    if (countries[country.ID].myTeamIndex == currentPlayerIndex) {
      selectedCountryIndex = country.ID;
    }
  } else {
    // Switch country
    if (country.myTeamIndex == currentPlayerIndex) {
      selectedCountryIndex = country.ID;
      return;
    }

    boolean isNeighbor = countries[selectedCountryIndex].isNeighboring(country);
    if (!isNeighbor) {
      selectedCountryIndex = -1;
      return;
    }
    if (countries[country.ID].myTeamIndex == -1) {
      countries[country.ID].myTeamIndex = currentPlayerIndex;
      selectedCountryIndex = -1;
    } else {
      // ATTACK!
    }
  }
}

