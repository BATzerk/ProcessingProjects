
// ======== AI STUFF ========
// AI difficulty/tuning knobs. Higher thresholds make bots more cautious;
// higher weights make them value that part of the board more strongly.
final float AI_MIN_ATTACK_SCORE = 62;
final float AI_WIN_CHANCE_WEIGHT = 100;
final float AI_CAPTURE_WEIGHT = 1.5;
final float AI_EMPTY_CAPTURE_BONUS = 18;
final float AI_GROUP_MERGE_WEIGHT = 6;
final float AI_ELIMINATION_BONUS = 45;
final float AI_EXPOSURE_PENALTY = 12;
final float AI_RANDOMNESS = 4;
final float AI_MIN_MIGRATION_SCORE = 18;
final float AI_MIGRATION_ATTACK_WEIGHT = 0.7;
final float AI_MIGRATION_FRONTIER_WEIGHT = 7;
final float AI_MIGRATION_SOURCE_DANGER_PENALTY = 10;
final int AI_MOVE_ATTACK = 0;
final int AI_MOVE_MIGRATE = 1;

class AI
{
  int myTeamIndex;
  int difficulty;

  AI(int team) {
    this(team, AI_DIFFICULTY_NORMAL);
  }

  AI(int team, int aiDifficulty) {
    myTeamIndex = team;
    difficulty = aiDifficulty;
  }

  void executeNextStep() {
    setGameMode(GAME_MODE_AI_TURN);

    AIMove bestMove = getBestMove();

    if (bestMove == null || isGameOver()) {
      startNextPlayerTurn();
      return;
    }

    setSelectedCountryIndex(bestMove.attacker.ID);
    if (bestMove.moveType == AI_MOVE_MIGRATE) {
      migrateDice(bestMove.attacker, bestMove.defender);
      return;
    } else {
      countryAttackOther(bestMove.attacker, bestMove.defender);
    }
  
    scheduleAction(SCHEDULED_ACTION_AI_STEP, isBattleMode() ? 3.0 : 0.5);
  }

  AIMove getBestMove() {
    AIMove bestAttack = null;
    AIMove bestMigration = null;
    Country[] selectableCountries = getSelectableCountries();
    for (int i=0; i<selectableCountries.length; i++) {
      Country attacker = selectableCountries[i];
      for (int n=0; n<attacker.neighbors.length; n++) {
        Country defender = attacker.neighbors[n];
        if (canCountryAttackOther(attacker, defender)) {
          float score = scoreAttack(attacker, defender);
          if (bestAttack == null || score > bestAttack.score) {
            bestAttack = new AIMove(attacker, defender, score, AI_MOVE_ATTACK);
          }
        }
      }
      for (int n=0; n<countries.length; n++) {
        Country defender = countries[n];
        if (canTeamMigrateDice(myTeamIndex, attacker, defender)) {
          float score = scoreMigration(attacker, defender);
          if (bestMigration == null || score > bestMigration.score) {
            bestMigration = new AIMove(attacker, defender, score, AI_MOVE_MIGRATE);
          }
        }
      }
    }
    if (bestAttack != null && bestAttack.score >= getMinAttackScore()) {
      return bestAttack;
    }
    if (bestMigration != null && bestMigration.score >= getMinMigrationScore()) {
      return bestMigration;
    }
    return null;
  }

  float scoreAttack(Country attacker, Country defender) {
    float winChance = getWinChance(attacker.myDice, defender.myDice);
    float score = winChance * AI_WIN_CHANCE_WEIGHT;

    score += getCaptureValue(defender) * AI_CAPTURE_WEIGHT;
    score += getGroupMergeValue(attacker, defender) * AI_GROUP_MERGE_WEIGHT;
    score += getEliminationValue(defender);
    score -= getExposureValue(attacker, defender) * getExposurePenalty();
    score += random(-getRandomness(), getRandomness());

    return score;
  }

  float scoreMigration(Country from, Country _to) {
    int targetDiceAfterMigration = _to.myDice + from.myDice - 1;
    float score = 0;

    score += getBestAttackOpportunity(_to, targetDiceAfterMigration) * AI_MIGRATION_ATTACK_WEIGHT;
    score -= getBestAttackOpportunity(_to, _to.myDice) * AI_MIGRATION_ATTACK_WEIGHT;
    score += countNonFriendlyNeighbors(_to) * AI_MIGRATION_FRONTIER_WEIGHT;
    score -= countNonFriendlyNeighbors(from) * AI_MIGRATION_SOURCE_DANGER_PENALTY;

    return score;
  }

  float getMinAttackScore() {
    switch (difficulty) {
      case AI_DIFFICULTY_EASY: return 74;
      case AI_DIFFICULTY_HARD: return 54;
      default: return AI_MIN_ATTACK_SCORE;
    }
  }

  float getMinMigrationScore() {
    switch (difficulty) {
      case AI_DIFFICULTY_EASY: return 34;
      case AI_DIFFICULTY_HARD: return 12;
      default: return AI_MIN_MIGRATION_SCORE;
    }
  }

  float getExposurePenalty() {
    switch (difficulty) {
      case AI_DIFFICULTY_EASY: return 4;
      case AI_DIFFICULTY_HARD: return 16;
      default: return AI_EXPOSURE_PENALTY;
    }
  }

  float getRandomness() {
    switch (difficulty) {
      case AI_DIFFICULTY_EASY: return 24;
      case AI_DIFFICULTY_HARD: return 1;
      default: return AI_RANDOMNESS;
    }
  }

  float getBestAttackOpportunity(Country attacker, int attackDice) {
    float bestScore = 0;
    for (int i=0; i<attacker.neighbors.length; i++) {
      Country defender = attacker.neighbors[i];
      if (!canDiceAttackCountry(attackDice, defender)) {
        continue;
      }
      float score = getWinChance(attackDice, defender.myDice) * AI_WIN_CHANCE_WEIGHT;
      score += getCaptureValue(defender) * AI_CAPTURE_WEIGHT;
      if (score > bestScore) {
        bestScore = score;
      }
    }
    return bestScore;
  }

  int countNonFriendlyNeighbors(Country country) {
    int count = 0;
    for (int i=0; i<country.neighbors.length; i++) {
      if (country.neighbors[i].myTeamIndex != myTeamIndex) {
        count++;
      }
    }
    return count;
  }

  float getCaptureValue(Country defender) {
    float value = defender.cells.size();
    if (defender.myTeamIndex == -1) {
      value += AI_EMPTY_CAPTURE_BONUS;
    } else {
      value += defender.myDice;
    }
    return value;
  }

  float getGroupMergeValue(Country attacker, Country defender) {
    int[] attackerGroup = attacker.getMyCountryGroup();
    Set<Integer> connectedIds = new HashSet<Integer>();
    for (int i=0; i<attackerGroup.length; i++) {
      connectedIds.add(attackerGroup[i]);
    }

    int value = 0;
    for (int i=0; i<defender.neighbors.length; i++) {
      Country neighbor = defender.neighbors[i];
      if (neighbor.myTeamIndex != myTeamIndex || connectedIds.contains(neighbor.ID)) {
        continue;
      }

      int[] group = neighbor.getMyCountryGroup();
      value += group.length;
      for (int g=0; g<group.length; g++) {
        connectedIds.add(group[g]);
      }
    }
    return value;
  }

  float getEliminationValue(Country defender) {
    if (defender.myTeamIndex == -1) {
      return 0;
    }

    int defenderCountries = 0;
    for (int i=0; i<countries.length; i++) {
      if (countries[i].myTeamIndex == defender.myTeamIndex) {
        defenderCountries++;
      }
    }
    return defenderCountries == 1 ? AI_ELIMINATION_BONUS : 0;
  }

  float getExposureValue(Country attacker, Country defender) {
    int diceMoved = attacker.myDice - 1;
    if (defender.cells.size() < diceMoved) {
      diceMoved = defender.cells.size();
    }

    int strongestThreat = 0;
    for (int i=0; i<defender.neighbors.length; i++) {
      Country neighbor = defender.neighbors[i];
      if (neighbor.ID != attacker.ID && neighbor.myTeamIndex != myTeamIndex && neighbor.myDice > strongestThreat) {
        strongestThreat = neighbor.myDice;
      }
    }

    float exposedTarget = max(0, strongestThreat - diceMoved);
    float weakenedSource = attackerHasEnemyNeighborOtherThan(attacker, defender) ? 1 : 0;
    return exposedTarget + weakenedSource;
  }

  boolean attackerHasEnemyNeighborOtherThan(Country attacker, Country ignoredCountry) {
    for (int i=0; i<attacker.neighbors.length; i++) {
      Country neighbor = attacker.neighbors[i];
      if (neighbor.ID != ignoredCountry.ID && neighbor.myTeamIndex != myTeamIndex) {
        return true;
      }
    }
    return false;
  }

  Country[] getSelectableCountries() {
    ArrayList<Country> list = new ArrayList<Country>();
    for (int i=0; i<countries.length; i++) {
      if (countries[i].myTeamIndex == this.myTeamIndex && countries[i].myDice>1) {
        list.add(countries[i]);
      }
    }
    // Convert to array.
    return list.toArray(new Country[list.size()]);
  }

  Country[] getAttackableCountriesWithAttackAdvantage() {
    // Safety check.
    if (selectedCountryIndex < 0) { return null; }
    Country selectedCountry = countries[selectedCountryIndex];
    ArrayList<Country> list = new ArrayList<Country>();
    for (int i=0; i<selectedCountry.neighbors.length; i++) {
      if (shouldCountryAttackOther(selectedCountry, selectedCountry.neighbors[i])) {
        list.add(selectedCountry.neighbors[i]);
      }
    }
    // Convert to array.
    return list.toArray(new Country[list.size()]);
  }
  Country[] getAttackableCountries() {
    // Safety check.
    if (selectedCountryIndex < 0) { return null; }
    Country selectedCountry = countries[selectedCountryIndex];
    ArrayList<Country> list = new ArrayList<Country>();
    for (int i=0; i<selectedCountry.neighbors.length; i++) {
      if (canCountryAttackOther(selectedCountry, selectedCountry.neighbors[i])) {
        list.add(selectedCountry.neighbors[i]);
      }
    }
    // Convert to array.
    return list.toArray(new Country[list.size()]);
  }
  boolean canCountryAttackOther(Country attacker, Country defender) {
    return canTeamAttackCountry(myTeamIndex, attacker, defender)
      && attacker.myDice * DICE_SIDES > defender.myDice;
  }
  boolean canDiceAttackCountry(int attackDice, Country defender) {
    if (defender.myTeamIndex == myTeamIndex) { return false; }
    if (attackDice <= 1) { return false; }
    if (attackDice*6 <= defender.myDice) { return false; }
    return true;
  }
  boolean shouldCountryAttackOther(Country attacker, Country defender) {
    // It isn't ALLOWED to attack? Return false, of course.
    if (!canCountryAttackOther(attacker, defender)) { return false; }
    // Return if attacker has dice advantage!
    return attacker.myDice >= defender.myDice;
  }
}

class AIMove
{
  Country attacker;
  Country defender;
  float score;
  int moveType;

  AIMove(Country attacker, Country defender, float score, int moveType) {
    this.attacker = attacker;
    this.defender = defender;
    this.score = score;
    this.moveType = moveType;
  }
}
