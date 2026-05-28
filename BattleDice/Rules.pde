boolean canSelectCountry(Country country) {
  return country != null
    && country.myTeamIndex == currPlayerIndex
    && country.myDice > 1;
}

boolean canAttackCountry(Country attacker, Country defender) {
  return canTeamAttackCountry(currPlayerIndex, attacker, defender);
}

boolean canTeamAttackCountry(int teamIndex, Country attacker, Country defender) {
  return attacker != null
    && defender != null
    && attacker.ID != defender.ID
    && attacker.myDice > 1
    && attacker.myTeamIndex == teamIndex
    && defender.myTeamIndex != teamIndex
    && attacker.isNeighboring(defender);
}

float getWinChance(int attackDice, int defendDice) {
  if (defendDice <= 0 || attackDice > defendDice * DICE_SIDES) {
    return 1;
  }
  if (isWinChanceCacheable(attackDice, defendDice) && winChanceCached[attackDice][defendDice]) {
    return winChanceCache[attackDice][defendDice];
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
  if (isWinChanceCacheable(attackDice, defendDice)) {
    winChanceCache[attackDice][defendDice] = chance;
    winChanceCached[attackDice][defendDice] = true;
  }
  return chance;
}

boolean isWinChanceCacheable(int attackDice, int defendDice) {
  return attackDice >= 0
    && defendDice >= 0
    && attackDice < winChanceCache.length
    && defendDice < winChanceCache[attackDice].length;
}

float[] getDiceSumOdds(int diceCount) {
  if (diceCount >= 0 && diceCount < diceSumOddsCache.length && diceSumOddsCache[diceCount] != null) {
    return diceSumOddsCache[diceCount];
  }

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
  if (diceCount >= 0 && diceCount < diceSumOddsCache.length) {
    diceSumOddsCache[diceCount] = odds;
  }
  return odds;
}

boolean canMigrateDice(Country from, Country _to) {
  return canTeamMigrateDice(currPlayerIndex, from, _to);
}

boolean canTeamMigrateDice(int teamIndex, Country from, Country _to) {
  return from != null
    && _to != null
    && from.ID != _to.ID
    && from.myDice > 1
    && from.myTeamIndex == teamIndex
    && _to.myTeamIndex == teamIndex
    && areCountriesInSameOwnedGroup(from, _to)
    && getMigrationDiceCount(from, _to) > 0;
}

int getMigrationDiceCount(Country from, Country _to) {
  if (from == null || _to == null) {
    return 0;
  }
  int diceAvailable = from.myDice - 1;
  int targetCapacity = _to.cells.size() - _to.myDice;
  return max(0, min(diceAvailable, targetCapacity));
}

boolean canActOnCountry(Country from, Country _to) {
  return canAttackCountry(from, _to) || canMigrateDice(from, _to);
}

boolean areCountriesInSameOwnedGroup(Country from, Country _to) {
  if (from == null || _to == null || from.myTeamIndex != _to.myTeamIndex) {
    return false;
  }

  int[] group = from.getMyCountryGroup();
  for (int i=0; i<group.length; i++) {
    if (group[i] == _to.ID) {
      return true;
    }
  }
  return false;
}
