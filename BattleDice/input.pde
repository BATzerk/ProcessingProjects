

void keyPressed() {
  if (isPlayerSelectScreen()) {
    handlePlayerSelectKeyPressed();
    return;
  }

  if (key == 'q' || key == 'Q' || keyCode == 'Q') {
    returnToPlayerSelectScreen();
  }
  else if ((key == 'r' || key == 'R' || keyCode == 'R') && keyEvent.isControlDown()) {
    startNewGame();
  }
  else if (key == 'd') {
    doHideBattleDice = !doHideBattleDice;
  }
  else if (key == 'a') {
    if (botPlayers[currPlayerIndex] == null) {
      botPlayers[currPlayerIndex] = createAIForTeam(currPlayerIndex);
      if (!isBattleMode() && !isGameOver()) {
        botPlayers[currPlayerIndex].executeNextStep();
      }
    } else {
      botPlayers[currPlayerIndex] = null;
      setCurrentTurnMode();
      statusText = getPlayerName(currPlayerIndex) + " is now human-controlled.";
    }
  }
  else if (key == 't') {
    timeScale = timeScale>1 ? NORMAL_TIME_SCALE : 1000;
  }
  else if (key == 'f' || key == 'F') {
    timeScale = FAST_FORWARD_TIME_SCALE;
  }
  else if (keyCode == ENTER && !isBattleMode() && !isMigrationMode() && !isGameOver() && isCurrentPlayerHuman()) {
    startNextPlayerTurn();
  }
}

void keyReleased() {
  if (key == 'f' || key == 'F') {
    timeScale = NORMAL_TIME_SCALE;
  }
}


void mousePressed() {
  if (isPlayerSelectScreen()) {
    handlePlayerSelectMousePressed();
    return;
  }

  if (!isCurrentPlayerHuman() || isBattleMode() || isMigrationMode() || isGameOver()) {
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
      statusText = "Selected. Click a neighboring enemy or empty country to attack, or a connected country with room to migrate.";
    } else if (country.myTeamIndex == currPlayerIndex) {
      statusText = "That country only has 1 die, so it cannot attack or migrate.";
    } else {
      statusText = "That is not your country. Click one of your own countries first.";
    }
  } else { // Clicking second country (already have selection)
    Country selectedCountry = countries[selectedCountryIndex];

    if (!canActOnCountry(selectedCountry, country)) {
      setSelectedCountryIndex(-1);
      if (country.myTeamIndex == currPlayerIndex && areCountriesInSameOwnedGroup(selectedCountry, country)) {
        statusText = "That country does not have room for all but one die.";
      } else {
        statusText = "Deselected. Click one of your countries with 2+ dice.";
      }
      return;
    }
    if (canMigrateDice(selectedCountry, country)) {
      migrateDice(selectedCountry, country);
    } else {
      countryAttackOther(selectedCountry, country);
    }
  }
}
