
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

class AI
{
  int myTeamIndex;

  AI(int team) {
    myTeamIndex = team;
  }

  void executeNextStep() {
    isAIExecutingTurn = true;

    AIMove bestMove = getBestMove();

    if (bestMove == null || bestMove.score < AI_MIN_ATTACK_SCORE || isGameOver) {
      startNextPlayerTurn();
      return;
    }

    setSelectedCountryIndex(bestMove.attacker.ID);
    countryAttackOther(bestMove.attacker, bestMove.defender);
  
    // Plan when to do next step. NOTE: FRAGILE! Timer runs concurrently with battle timer. IDEALLY, we'd only have ONE timer. It's "timeWhenNextStep", and when it's time, it'd call a function that handles what to do.
    timeWhenNextAIStep = currTime + (isBattleMode ? 3.0 : 0.5);
  }

  AIMove getBestMove() {
    AIMove bestMove = null;
    Country[] selectableCountries = getSelectableCountries();
    for (int i=0; i<selectableCountries.length; i++) {
      Country attacker = selectableCountries[i];
      for (int n=0; n<attacker.neighbors.length; n++) {
        Country defender = attacker.neighbors[n];
        if (!canCountryAttackOther(attacker, defender)) {
          continue;
        }
        float score = scoreAttack(attacker, defender);
        if (bestMove == null || score > bestMove.score) {
          bestMove = new AIMove(attacker, defender, score);
        }
      }
    }
    return bestMove;
  }

  float scoreAttack(Country attacker, Country defender) {
    float winChance = getWinChance(attacker.myDice, defender.myDice);
    float score = winChance * AI_WIN_CHANCE_WEIGHT;

    score += getCaptureValue(defender) * AI_CAPTURE_WEIGHT;
    score += getGroupMergeValue(attacker, defender) * AI_GROUP_MERGE_WEIGHT;
    score += getEliminationValue(defender);
    score -= getExposureValue(attacker, defender) * AI_EXPOSURE_PENALTY;
    score += random(-AI_RANDOMNESS, AI_RANDOMNESS);

    return score;
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

  float getWinChance(int attackDice, int defendDice) {
    if (defendDice <= 0 || attackDice > defendDice * DICE_SIDES) {
      return 1;
    }

    float[] attackOdds = getDiceSumOdds(attackDice);
    float[] defendOdds = getDiceSumOdds(defendDice);
    float chance = 0;
    for (int attackSum=0; attackSum<attackOdds.length; attackSum++) {
      if (attackOdds[attackSum] == 0) {
        continue;
      }
      for (int defendSum=0; defendSum<defendOdds.length && defendSum<attackSum; defendSum++) {
        chance += attackOdds[attackSum] * defendOdds[defendSum];
      }
    }
    return chance;
  }

  float[] getDiceSumOdds(int diceCount) {
    float[] odds = new float[diceCount * DICE_SIDES + 1];
    odds[0] = 1;
    for (int d=0; d<diceCount; d++) {
      float[] nextOdds = new float[diceCount * DICE_SIDES + 1];
      for (int sum=0; sum<odds.length; sum++) {
        if (odds[sum] == 0) {
          continue;
        }
        for (int roll=1; roll<=DICE_SIDES; roll++) {
          nextOdds[sum + roll] += odds[sum] / DICE_SIDES;
        }
      }
      odds = nextOdds;
    }
    return odds;
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
    // Can't attack same team.
    if (attacker.myTeamIndex == defender.myTeamIndex) { return false; }
    // Not enough dice to even attack, man.
    if (attacker.myDice <= 1) { return false; }
    // So few dice it'd be a guaranteed loss? Return false.
    if (attacker.myDice*6 <= defender.myDice) { return false; }
    // Sure, why not!
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

  AIMove(Country attacker, Country defender, float score) {
    this.attacker = attacker;
    this.defender = defender;
    this.score = score;
  }
}
