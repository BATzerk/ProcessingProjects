int[] attackDice, defendDice;

void setupBattle(Country offense, Country defense) {
  attackingCountry = offense;
  defendingCountry = defense;
  timeWhenStartedRolling = currTime;
  attackDice = new int[offense.myDice];
  defendDice = new int[defense.myDice];
  isBattleMode = true;
}

int d6() {
  return floor(random(5)) + 1;
}

void rollBattleDice() {
  attackSum = 0;
  for (int i = 0; i < attackDice.length; i++) {
    int roll = d6();
    attackSum += roll;
    attackDice[i] = roll;
  }
  defendSum = 0;
  for (int i = 0; i < defendDice.length; i++) {
    int roll = d6();
    defendSum += roll;
    defendDice[i] = roll;
  }
}

void showBattleDice() {
  fill(teamColor(attackingCountry.myTeamIndex, 120));
  rect(0, 0, width/2, height);
  fill(teamColor(defendingCountry.myTeamIndex, 120));
  rect(width/2, 0, width/2, height);

  fill(0, 120);
  rect(0, 0, width, height);

  textSize(96);
  fill(0);
  text(attackSum, width * 1/4, 152);
  text(defendSum, width * 3/4, 152);
  fill(255);
  text(attackSum, width * 1/4, 150);
  text(defendSum, width * 3/4, 150);

  textSize(24);
  float spacing = (width / 2) / 7;
  for (int i = 0; i < attackDice.length; i++) {
    float x = (i % 6 + 1) * spacing;
    float y = floor(i / 6) * spacing + 300;
    fill(255);
    drawHexagon(x, y, spacing / 2);
    fill(0);
    text(attackDice[i], x, y-3);
  }
  for (int i = 0; i < defendDice.length; i++) {
    float x = (i % 6 + 1) * spacing + width/2;
    float y = floor(i / 6) * spacing + 300;
    fill(255);
    drawHexagon(x, y, spacing / 2);
    fill(0);
    text(defendDice[i], x, y-3);
  }
}
