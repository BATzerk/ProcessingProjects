

// ======== GRID SETUP ========
void startNewGame() {
  // ---- Reset Gameplay Variables ----
  {
    setGameMode(GAME_MODE_HUMAN_TURN);
    eliminated = new boolean[NUM_PLAYERS]; // assuming this fills false
    botPlayers = new AI[NUM_PLAYERS]; // assuming this fills false
    setCurrPlayerIndex(0);
    turnCount = 1;
    setSelectedCountryIndex(-1);
    resetPlayerLuckiness();
    attackingCountry = null;
    defendingCountry = null;
    migrationFromCountry = null;
    migrationToCountry = null;
    migrationDiceCount = 0;
    migrationDieStartPositions = null;
    migrationDieEndPositions = null;
    statusText = "";
    clearScheduledAction();
    timeScale = NORMAL_TIME_SCALE;
    doHideBattleDice = false;
  }
  // ---- Remake Grid to Good Layout ----
  {
    println("\n=== brb, making new world ===");
    int tries=0;
    for (tries=0; tries<=5000; tries++) { // try a bunch of times.
      remakeGridTotallyRandomly();

      // Assign starting countries
      Set<Integer> invalid = new HashSet<Integer>(); // save taken and nearby starts
      int assigned = 0;
      for (int i = 0; assigned < NUM_PLAYERS && i < countries.length; i++) {
        if (invalid.contains(i)) {
          continue;
        }
        if (!canCountryHoldStartingDice(countries[i])) {
          continue;
        }
        countries[i].myTeamIndex = assigned++;
        countries[i].myDice = NUM_STARTING_DICE_PER_TEAM;

        addCountriesWithinStartingDistance(countries[i], invalid);
      }

      // Moved so we see the error if we give up
      Quality currentGridLayoutIsGood = isCurrentGridLayoutGood();

      if (currentGridLayoutIsGood == Quality.IMPOSSIBLE) {
        continue;
      }

      if (assigned < NUM_PLAYERS) {
        println("= Could only assign " + assigned + " players.");
        continue;
      }

      if (currentGridLayoutIsGood == Quality.BAD && tries >= 50) {
        println("= Error! Could not find good layout. Oh well, going with this one.");
        break;
      }

      if (currentGridLayoutIsGood == Quality.GOOD) {
        break;
      }
    }
  }

  for (int i = 0; i < NUM_PLAYERS; i++) {
    if (!isPlayerHumanControlled(i)) {
      botPlayers[i] = createAIForTeam(i);
    }
  }
  if (setupHumanCount > 0) {
    statusText = "Click one of your countries with 2+ dice.";
  }
  startAITurnIfNeeded();
}

void remakeGridTotallyRandomly() {
  int cols = GRID_WIDTH;
  int rows = GRID_HEIGHT;
  float gw = cols * tileRadius * 1.678;
  float gh = rows * tileRadius * 1.44;

  // Cells
  gridCells = new Cell[cols][rows];
  for (int i = 0; i < gridCells.length; i++) {
    for (int j = 0; j < gridCells[i].length; j++) {
      gridCells[i][j] = new Cell(i, j);
    }
  }

  gridPos = new PVector((width - gw) / 2, (height - gh) / 2);

  // Countries
  int numCountries = cols * rows / 18;
  countries = new Country[numCountries];
  for (int i = 0; i < countries.length; i++) {
    countries[i] = new Country(i, getRandomEmptyCell());
  }
  for (int i = 0; i < 100; i++) {
    growCountryStep();
  }

  // Learn neighbors
  for (int i = 0; i < countries.length; i++) {
    countries[i].learnNeighbors();
  }
}

void addCountriesWithinStartingDistance(Country country, Set<Integer> invalid) {
  addCountriesWithinDistance(country, STARTING_COUNTRY_MIN_DISTANCE - 1, invalid, new HashSet<Integer>());
}

void addCountriesWithinDistance(Country country, int distanceRemaining, Set<Integer> ids, Set<Integer> checked) {
  if (country == null || checked.contains(country.ID)) {
    return;
  }

  checked.add(country.ID);
  ids.add(country.ID);
  if (distanceRemaining <= 0) {
    return;
  }

  for (int i = 0; i < country.neighbors.length; i++) {
    addCountriesWithinDistance(country.neighbors[i], distanceRemaining - 1, ids, checked);
  }
}

void growCountryStep() {
  for (int i = 0; i < countries.length; i++) {
    if (countries[i].cells.size() == MAX_CELLS_PER_COUNTRY) {
      continue;
    }
    Cell newFriend;
    boolean shouldAddCell = false;
    int numAttemptsLeft = 2;
    do {
      Cell edge = countries[i].getRandomEdgeCell();
      int face = floor(random(NUM_FACES));
      newFriend = edge.getNeighbor(face);
      shouldAddCell = canGenerateLandAt(newFriend);
      numAttemptsLeft --;
    } while (numAttemptsLeft > 0 && !shouldAddCell);

    if (shouldAddCell) {
      countries[i].addCell(newFriend);
    }
  }
}


// ======== TAKING TURNS ========
void setCurrPlayerIndex(int index) {
  while (eliminated[index]) {
    index = (index + 1) % NUM_PLAYERS;
  }
  currPlayerIndex = index;
  currPlayerName = getPlayerName(currPlayerIndex);
  setSelectedCountryIndex(-1);
}
boolean isCurrentPlayerHuman() {
  return botPlayers[currPlayerIndex] == null;
}
void startAITurnIfNeeded() {
  if (isGameOver()) {
    return;
  }
  setCurrentTurnMode();
  if (botPlayers[currPlayerIndex] != null) {
    botPlayers[currPlayerIndex].executeNextStep();
  }
}
void setSelectedCountryIndex(int index) {
  selectedCountryIndex = index;
}

boolean isCountryInCurrentBattle(int countryIndex) {
  return isBattleMode()
    && (
      (attackingCountry != null && attackingCountry.ID == countryIndex)
      || (defendingCountry != null && defendingCountry.ID == countryIndex)
    );
}

boolean isCountryRaisedForDrawing(int countryIndex) {
  return countryIndex == selectedCountryIndex || isCountryInCurrentBattle(countryIndex);
}

int getVisibleCountryDiceCount(Country country) {
  if (isMigrationMode() && migrationFromCountry != null && country.ID == migrationFromCountry.ID) {
    return 1;
  }
  return country.myDice;
}

void updateCountryDisplayOffsets() {
  for (int i=0; i<countries.length; i++) {
    float targetOffsetY = 0;
    if (isCountryInCurrentBattle(i)) {
      targetOffsetY = BATTLE_COUNTRY_RAISE;
    }
    else if (i == selectedCountryIndex) {
      targetOffsetY = SELECTED_COUNTRY_RAISE
        + sin(currTime * SELECTED_COUNTRY_BOB_SPEED) * SELECTED_COUNTRY_BOB_AMOUNT;
    }
    countries[i].displayOffsetY = targetOffsetY;
  }
}
void startNextPlayerTurn() {
  // Set currPlayerIndex
  setCurrPlayerIndex((currPlayerIndex + 1) % NUM_PLAYERS);
  currPlayerName = getPlayerName(currPlayerIndex);

  // === Distribute dice === //
  if (turnCount >= NUM_PLAYERS) { // don't give out dice on the first round
    ArrayList<int[]> groups = getCountryGroups(currPlayerIndex);
    for (int[] group: groups) { // for each group
      int bank = group.length; // Rubberbanding, min 3 per group max(3, group.length);
      int index = 0;
      int limit = 100; // in case we're all full
      while (limit-- > 0 && bank > 0) {
        Country country = countries[group[index]];
        if (country.myDice < country.cells.size()) { // room to grow!
          country.myDice ++;
          bank--;
        }
        index = (index + 1) % group.length;
      }
    }
  }
  turnCount ++;
  statusText = isCurrentPlayerHuman()
    ? "Your turn. Click one of your countries with 2+ dice, or press ENTER to pass."
    : "";

  // Run AI
  startAITurnIfNeeded();
}

void countryAttackOther(Country attacker, Country defender) {
  if (defender.myTeamIndex == -1) { // take empty countries
    moveIntoCountry(attacker, defender);
  }
  else { // fight occupied countries
    setupBattle(attacker, defender);
  }
}

void migrateDice(Country from, Country _to) {
  startMigrationDice(from, _to);
}

void startMigrationDice(Country from, Country _to) {
  migrationDiceCount = from.myDice - 1;
  migrationFromCountry = from;
  migrationToCountry = _to;
  enterMigrationMode();
  timeWhenStartedMigration = currTime;
  setSelectedCountryIndex(-1);
  updateCountryDisplayOffsets();

  migrationDieStartPositions = new PVector[migrationDiceCount];
  migrationDieEndPositions = new PVector[migrationDiceCount];
  for (int i = 0; i < migrationDiceCount; i++) {
    migrationDieStartPositions[i] = getCountryDieScreenPos(from, i + 1);
    migrationDieEndPositions[i] = getCountryDieScreenPos(_to, _to.myDice + i);
  }

  if (isCurrentPlayerHuman()) {
    statusText = "Moving " + migrationDiceCount + " dice. Turn ending...";
  }
}

float currentMigrationDuration() {
  return MIGRATION_DURATION + max(0, migrationDiceCount - 1) * MIGRATION_DIE_STAGGER;
}

void finishMigrationDice() {
  if (!isMigrationMode()) {
    return;
  }

  migrationToCountry.myDice += migrationDiceCount;
  migrationFromCountry.myDice = 1;
  if (isCurrentPlayerHuman()) {
    statusText = "Moved " + migrationDiceCount + " dice. Turn ended.";
  }
  migrationFromCountry = null;
  migrationToCountry = null;
  migrationDiceCount = 0;
  migrationDieStartPositions = null;
  migrationDieEndPositions = null;
  startNextPlayerTurn();
}

void drawMigrationDice() {
  if (!isMigrationMode() || migrationDieStartPositions == null || migrationDieEndPositions == null) {
    return;
  }

  pushStyle();
  fill(250);
  stroke(teamColor(currPlayerIndex));
  strokeWeight(2);
  for (int i = 0; i < migrationDiceCount; i++) {
    float elapsed = currTime - timeWhenStartedMigration - i * MIGRATION_DIE_STAGGER;
    float t = easeInOut(elapsed / MIGRATION_DURATION);
    if (t <= 0) {
      continue;
    }
    PVector pos = PVector.lerp(migrationDieStartPositions[i], migrationDieEndPositions[i], t);
    pos.y -= sin(t * PI) * MIGRATION_DIE_ARC_HEIGHT;
    drawHexagon(pos, tileRadius * COUNTRY_DIE_RADIUS_SCALE);
  }
  popStyle();
}

void moveIntoCountry(Country from, Country _to) {
  int victimPlayerIndex = _to.myTeamIndex;
  _to.myTeamIndex = currPlayerIndex;
  int targetCapacity = _to.cells.size();
  int diceToGive = from.myDice - 1;
  if (targetCapacity < diceToGive) {
    diceToGive = targetCapacity;
  }
  _to.myDice = diceToGive;
  from.myDice -= diceToGive;
  setSelectedCountryIndex(-1);
  if (isCurrentPlayerHuman()) {
    statusText = "Captured country. Attack again, or press ENTER to end your turn.";
  }

  // Is player eliminated?
  if (victimPlayerIndex > -1) {
    for (int i = 0; i < countries.length; i++) {
      if (countries[i].myTeamIndex == victimPlayerIndex) {
        return;
      }
    }
    println(getPlayerName(victimPlayerIndex) + " eliminated.");
    statusText = getPlayerName(victimPlayerIndex) + " eliminated.";
    eliminated[victimPlayerIndex] = true;

    int playersRemaining = 0;
    for (int b = 0; b < eliminated.length; b++) {
      if (!eliminated[b]) {
        playersRemaining++;
      }
    }
    if (playersRemaining == 1) {
      enterGameOverMode();
      statusText = currPlayerName + " wins. Press CTRL+R for a new game.";
      for (int i = 0; i < countries.length; i++) {
        countries[i].myDice = countries[i].cells.size();
      }
    }
  }
}
