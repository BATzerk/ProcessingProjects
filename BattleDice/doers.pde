

// ======== GRID SETUP ========
void startNewGame() {
  // ---- Reset Gameplay Variables ----
  {
    eliminated = new boolean[numOfPlayers]; // assuming this fills false
    setCurrPlayerIndex(0);
    turnCount = 1;
    setSelectedCountryIndex(-1);
    isBattleMode = false;
    attackingCountry = null;
    defendingCountry = null;
  }
  // ---- Remake Grid to Good Layout ----
  {
    int i=0;
    for (i=0; i<=50; i++) { // try a bunch of times.
      remakeGridTotallyRandomly();
      if (isCurrentGridLayoutGood()) { break; }
      if (i>=20) {
        println("Error! Could not find good layout. Oh well, going with this one.");
      }
    }

    // Assign starting countries
    for (i = 0; i < numOfPlayers; i++) {
      countries[i].myTeamIndex = i;
      countries[i].myDice = NUM_STARTING_DICE_PER_TEAM;
    }
  }
}

void remakeGridTotallyRandomly() {
  int cols = 30;
  int rows = 22;
  float gw = cols * tileRadius * 2/3 * sqrt(6);
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
    index = (index + 1) % numOfPlayers;
  }
  currPlayerIndex = index;
  currPlayerName = getPlayerName(currPlayerIndex);
  setSelectedCountryIndex(-1);
  isBattleMode = false;
}
void setSelectedCountryIndex(int index) {
  selectedCountryIndex = index;
  // Tell all countries what's up.
  for (int i=0; i<countries.length; i++) {
    boolean isSelectedCountry = i == selectedCountryIndex;
    countries[i].displayOffsetY = isSelectedCountry ? -6 : 0;
  }
}
void endTurn() {
  // Set currPlayerIndex
  setCurrPlayerIndex((currPlayerIndex + 1) % numOfPlayers);
  currPlayerName = getPlayerName(currPlayerIndex);

  // === Distribute dice === //
  if (turnCount >= numOfPlayers) { // don't give out dice on the first round
    ArrayList<int[]> groups = getCountryGroups(currPlayerIndex);
    for (int[] group: groups) { // for each group
      int bank = group.length;
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
  for (int i = 0; i < countries.length; i++) {
    if (countries[i].myTeamIndex == victimPlayerIndex) {
      return;
    }
  }
  println(getPlayerName(victimPlayerIndex) + " eliminiated.");
  eliminated[victimPlayerIndex] = true;
}
