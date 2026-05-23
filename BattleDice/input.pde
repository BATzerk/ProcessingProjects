

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
      if (!isBattleMode && !isGameOver) {
        botPlayers[currPlayerIndex].executeNextStep();
      }
    } else {
      isAIExecutingTurn = false;
      botPlayers[currPlayerIndex] = null;
      statusText = getPlayerName(currPlayerIndex) + " is now human-controlled.";
    }
  }
  else if (key == 't') {
    timeScale = timeScale>1 ? NORMAL_TIME_SCALE : 1000;
  }
  else if (key == 'f' || key == 'F') {
    timeScale = timeScale>1 ? NORMAL_TIME_SCALE : FAST_FORWARD_TIME_SCALE;
  }
  else if (keyCode == ENTER && !isBattleMode && !isGameOver && isCurrentPlayerHuman()) {
    startNextPlayerTurn();
  }
}


void mousePressed() {
  if (!isCurrentPlayerHuman() || isBattleMode || isGameOver) {
    return;
  }

  if (isMouseOverEndTurnButton()) {
    startNextPlayerTurn();
    return;
  }

  Cell cellMouse = getPlayableCellByScreenPos(mouseX, mouseY);
  if (cellMouse == null) {
    setSelectedCountryIndex(-1);
    statusText = "No country there. Click one of your countries with 2+ dice.";
    return;
  }

  Country country = cellMouse.myCountry;

  if (selectedCountryIndex == -1) { // If no country selected
    if (canSelectCountry(country)) {
      setSelectedCountryIndex(country.ID);
      statusText = "Selected. Click a neighboring enemy or empty country to attack.";
    } else if (country.myTeamIndex == currPlayerIndex) {
      statusText = "That country only has 1 die, so it cannot attack.";
    } else {
      statusText = "That is not your country. Click one of your own countries first.";
    }
  } else { // Clicking second country (already have selection)
    Country selectedCountry = countries[selectedCountryIndex];

    if (!canAttackCountry(selectedCountry, country)) {
      setSelectedCountryIndex(-1);
      statusText = "Deselected. Click one of your countries with 2+ dice.";
      return;
    }
    countryAttackOther(selectedCountry, country);
  }
}
