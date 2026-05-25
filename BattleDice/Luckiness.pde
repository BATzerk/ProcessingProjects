float[] playerLuckiness;

void resetPlayerLuckiness() {
  playerLuckiness = new float[playerCount];
}

void recordBattleLuckiness(Country attacker, Country defender, boolean attackerWon) {
  if (attacker == null || defender == null || playerLuckiness == null) {
    return;
  }

  int attackerIndex = attacker.myTeamIndex;
  int defenderIndex = defender.myTeamIndex;
  if (attackerIndex < 0
    || defenderIndex < 0
    || attackerIndex >= playerLuckiness.length
    || defenderIndex >= playerLuckiness.length) {
    return;
  }

  float attackWinChance = getWinChance(attacker.myDice, defender.myDice);
  float attackerActual = attackerWon ? 1 : 0;
  float attackerLuck = attackerActual - attackWinChance;

  playerLuckiness[attackerIndex] += attackerLuck;
  playerLuckiness[defenderIndex] -= attackerLuck;
}

String getPlayerLuckinessLabel(int playerIndex) {
  if (playerLuckiness == null || playerIndex < 0 || playerIndex >= playerLuckiness.length) {
    return "luck\n0.0";
  }

  float value = playerLuckiness[playerIndex];
  String sign = value > 0 ? "+" : "";
  return "luck\n" + sign + nf(value, 0, PLAYER_LUCK_DECIMALS);
}

void drawPlayerLuckiness(int playerIndex, float bannerX, float bannerWidth, boolean isActive) {
  pushStyle();
  textAlign(RIGHT, TOP);
  textSize(isActive ? 12 : 11);
  textLeading(isActive ? 10 : 9);
  fill(isActive ? color(0, 145) : color(255, 170));
  text(getPlayerLuckinessLabel(playerIndex), bannerX + bannerWidth - 7, 5);
  popStyle();
}
