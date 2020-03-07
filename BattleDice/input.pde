void mousePressed() {
  Cell cellMouse = getPlayableCellByScreenPos(mouseX, mouseY);
  if (cellMouse == null) {
    selectedCountryIndex = -1;
    return;
  }

  Country country = cellMouse.myCountry;

  if (selectedCountryIndex == -1) {
    if (
      country.myTeamIndex == currentPlayerIndex
      && country.myDice > 1
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
      country.myTeamIndex = currentPlayerIndex;
      int targetCapacity = country.cells.size();
      int diceToGive = selectedCountry.myDice - 1;
      if (targetCapacity < diceToGive) {
        diceToGive = targetCapacity;
      }
      country.myDice = diceToGive;
      selectedCountry.myDice -= diceToGive;
      selectedCountryIndex = -1;
    } else {
      // ATTACK!
    }
  }
}
