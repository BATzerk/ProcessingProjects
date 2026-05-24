void runStartupRuleChecks() {
  int failures = 0;
  failures += checkDiceOddsTotal();
  failures += checkWinChanceValue("1v1 win chance", getWinChance(1, 1), 15.0 / 36.0);
  failures += checkWinChanceValue("guaranteed win chance", getWinChance(DICE_SIDES + 1, 1), 1);

  if (failures > 0) {
    println("Rule checks failed: " + failures);
  }
}

int checkDiceOddsTotal() {
  int failures = 0;
  for (int dice=1; dice<=MAX_CELLS_PER_COUNTRY; dice++) {
    float total = 0;
    float[] odds = getDiceSumOdds(dice);
    for (int i=0; i<odds.length; i++) {
      total += odds[i];
    }
    failures += checkWinChanceValue(dice + " dice odds total", total, 1);
  }
  return failures;
}

int checkWinChanceValue(String label, float actual, float expected) {
  if (abs(actual - expected) <= 0.0001) {
    return 0;
  }
  println("Rule check failed: " + label + " expected " + expected + " but got " + actual);
  return 1;
}
