void mousePressed() {
  Cell cellMouse = getPlayableCellByScreenPos(mouseX, mouseY);
  if (cellMouse == null) {
    selectedCountryIndex = -1;
    return;
  }
  
//  if (selectedCountryIndex == -1) {
//    if (countries[cellMouse.myCountry.ID].myTeamIndex == currentPlayerIndex) {
      selectedCountryIndex = cellMouse.myCountry.ID;
//    }
//  } else {
//    // if country not mine && countries neighboring
//      // ATTACK!
//  }
}
