

// ======== GRID SETUP ========
void startNewGame() {
  // ---- Reset Gameplay Variables ----
  {
    isGameOver = false;
    eliminated = new boolean[NUM_PLAYERS]; // assuming this fills false
    botPlayers = new AI[NUM_PLAYERS]; // assuming this fills false
    setCurrPlayerIndex(0);
    turnCount = 1;
    setSelectedCountryIndex(-1);
    isBattleMode = false;
    isAIExecutingTurn = false;
    attackingCountry = null;
    defendingCountry = null;
  }
  // ---- Remake Grid to Good Layout ----
  {
    println("\n=== brb, making new world ===");
    int tries=0;
    for (tries=0; tries<=5000; tries++) { // try a bunch of times.
      remakeGridTotallyRandomly();

      // Assign starting countries
      Set<Integer> invalid = new HashSet<Integer>(); // save taken and neighbors
      int assigned = 0;
      for (int i = 0; (MOVIE_MODE || assigned < NUM_PLAYERS) && i < countries.length; i++) {
        if (invalid.contains(i)) { // can't choose an existing neighbor
          continue;
        }
        countries[i].myTeamIndex = assigned++;
        countries[i].myDice = NUM_STARTING_DICE_PER_TEAM;

        invalid.add(i);
        for (int c = 0; c < countries[i].neighbors.length; c++) {
          invalid.add(countries[i].neighbors[c].ID);
        }
      }

      if (MOVIE_MODE) {
        NUM_PLAYERS = assigned;
      }
      if (assigned < NUM_PLAYERS) {
        println("= Could only assign " + assigned + " players.");
        continue;
      }

      // Moved so we see the error if we give up
      boolean currentGridLayoutIsGood = assigned == NUM_PLAYERS && isCurrentGridLayoutGood();

      if (tries >= 50) {
        println("= Error! Could not find good layout. Oh well, going with this one.");
        break;
      }

      if (currentGridLayoutIsGood) {
        break;
      }
    }
  }
  
  // === MOVIE MODE === //
  if (MOVIE_MODE) {
    doHideBattleDice = true;
    timeScale = 1000;
    eliminated = new boolean[NUM_PLAYERS]; // assuming this fills false
    botPlayers = new AI[NUM_PLAYERS]; // assuming this fills false
    for (int i = 0; i < NUM_PLAYERS; i++) {
      botPlayers[i] = new AI(i);
    }
  }
  botPlayers[0].executeNextStep();
}

void remakeGridTotallyRandomly() {
  int cols = GRID_WIDTH;
  int rows = GRID_HEIGHT;
  float gw = cols * tileRadius * 1.678;
  float gh = rows * tileRadius * 1.4;

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

void growCountryStep() {
  for (int i = 0; i < countries.length; i++) {
    if (countries[i].cells.size() == MAX_CELLS_PER_COUNTRY) {
      continue;
    }
    Cell newFriend;
    int numAttemptsLeft = 2;
    do {
      Cell edge = countries[i].getRandomEdgeCell();
      int face = floor(random(NUM_FACES));
      newFriend = edge.getNeighbor(face);
      numAttemptsLeft --;
    } while (numAttemptsLeft > 0 && (newFriend == null || newFriend.myCountry != null));

    if (newFriend != null && newFriend.myCountry == null) {
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
  isBattleMode = false;
  isAIExecutingTurn = false;
}
void setSelectedCountryIndex(int index) {
  selectedCountryIndex = index;
  // Tell all countries what's up.
  for (int i=0; i<countries.length; i++) {
    boolean isSelectedCountry = i == selectedCountryIndex;
    countries[i].displayOffsetY = isSelectedCountry ? -6 : 0;
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

  // Run AI
  if (!isGameOver && botPlayers[currPlayerIndex] != null) {
    botPlayers[currPlayerIndex].executeNextStep();
  }
}

void countryAttackOther(Country attacker, Country defender) {
  if (defender.myTeamIndex == -1) { // take empty countries
    moveIntoCountry(attacker, defender);
  }
  else { // fight occupied countries
    setupBattle(attacker, defender);
  }
}

void moveIntoCountry(Country from, Country to) {
  int victimPlayerIndex = to.myTeamIndex;
  to.myTeamIndex = currPlayerIndex;
  int targetCapacity = to.cells.size();
  int diceToGive = from.myDice - 1;
  if (targetCapacity < diceToGive) {
    diceToGive = targetCapacity;
  }
  to.myDice = diceToGive;
  from.myDice -= diceToGive;
  setSelectedCountryIndex(-1);

  // Is player eliminated?
  if (victimPlayerIndex > -1) {
    for (int i = 0; i < countries.length; i++) {
      if (countries[i].myTeamIndex == victimPlayerIndex) {
        return;
      }
    }
    println(getPlayerName(victimPlayerIndex) + " eliminiated.");
    eliminated[victimPlayerIndex] = true;
    
    int playersRemaining = 0;
    for (int b = 0; b < eliminated.length; b++) {
      if (!eliminated[b]) {
        playersRemaining++;
      }
    }
    if (playersRemaining == 1) {
      isGameOver = true;
      for (int i = 0; i < countries.length; i++) {
        countries[i].myDice = countries[i].cells.size();
      }
      if (MOVIE_MODE) {
        timeWhenStartNextGame = currTime + 3 * timeScale;
      }
    }
  }
}
