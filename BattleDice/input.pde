void mousePressed() {
  Cell cellMouse = getCellByScreenPos(mouseX, mouseY);
  if (cellMouse == null) {
    selectedCountryIndex = -1;
    return;
  }
  
  if (selectedCountryIndex == -1) {
    if (countries[cellMouse.myCountry].myTeamIndex == currentPlayerIndex) {
      selectedCountryIndex = cellMouse.myCountry;
    }
  } else {
    // if country not mine && countries neighboring
      // ATTACK!
  }
}
