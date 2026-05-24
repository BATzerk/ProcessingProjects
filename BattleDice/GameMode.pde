void setGameMode(int mode) {
  gameMode = mode;
}

void returnToPlayerSelectScreen() {
  clearScheduledAction();
  setSelectedCountryIndex(-1);
  attackingCountry = null;
  defendingCountry = null;
  migrationFromCountry = null;
  migrationToCountry = null;
  migrationDiceCount = 0;
  migrationDieStartPositions = null;
  migrationDieEndPositions = null;
  timeScale = NORMAL_TIME_SCALE;
  doHideBattleDice = false;
  statusText = "";
  setGameMode(GAME_MODE_PLAYER_SELECT);
}

void enterBattleMode() {
  setGameMode(GAME_MODE_BATTLE);
}

void enterMigrationMode() {
  setGameMode(GAME_MODE_MIGRATION);
}

void enterGameOverMode() {
  setGameMode(GAME_MODE_GAME_OVER);
  setDiceHistoryGraphVisible(true);
}

boolean isPlayerSelectScreen() {
  return gameMode == GAME_MODE_PLAYER_SELECT;
}

boolean isAITurnMode() {
  return gameMode == GAME_MODE_AI_TURN;
}

boolean isBattleMode() {
  return gameMode == GAME_MODE_BATTLE;
}

boolean isMigrationMode() {
  return gameMode == GAME_MODE_MIGRATION;
}

boolean isGameOver() {
  return gameMode == GAME_MODE_GAME_OVER;
}

void setCurrentTurnMode() {
  setGameMode(isCurrentPlayerHuman() ? GAME_MODE_HUMAN_TURN : GAME_MODE_AI_TURN);
}
