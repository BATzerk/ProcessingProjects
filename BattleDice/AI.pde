
// ======== AI STUFF ========
void AIExecuteNextStep() {
  isAIExecutingTurn = true;
  
  Country[] selectableCountries = getSelectableCountries();
  
  // No countries to pick from? End our turn!
  if (selectableCountries.length == 0) {
    startNextPlayerTurn();
    return;
  }
  
  // Pick a random country to select.
  int randIndexInMyList = floor(random(0, selectableCountries.length));
  setSelectedCountryIndex(selectableCountries[randIndexInMyList].ID);
  // Pick a random country to attack.
  Country[] attackableCountries = getAttackableCountries();
  // No countries to attack?? End our turn early! Don't try again.
  if (attackableCountries.length == 0) {
    startNextPlayerTurn();
    return;
  }
  Country selectedCountry = countries[selectedCountryIndex];
  Country defendingCountry = attackableCountries[floor(random(0,attackableCountries.length))];
  countryAttackOther(selectedCountry, defendingCountry);
  
  // Plan when to do next step. NOTE: FRAGILE! Timer runs concurrently with battle timer. IDEALLY, we'd only have ONE timer. It's "timeWhenNextStep", and when it's time, it'd call a function that handles what to do.
  timeWhenNextAIStep = millis() + (isBattleMode ? 3500 : 500);
}

Country[] getSelectableCountries() {
  ArrayList<Country> list = new ArrayList<Country>();
  for (int i=0; i<countries.length; i++) {
    if (countries[i].myTeamIndex == currPlayerIndex && countries[i].myDice>1) {
      list.add(countries[i]);
    }
  }
  // Convert to array.
  return list.toArray(new Country[list.size()]);
}
Country[] getAttackableCountries() {
  // Safety check.
  if (selectedCountryIndex < 0) {
    return null;
  }
  Country selectedCountry = countries[selectedCountryIndex];
  ArrayList<Country> list = new ArrayList<Country>();
  for (int i=0; i<selectedCountry.neighbors.length; i++) {
    if (mayCountryAttackOther(selectedCountry, selectedCountry.neighbors[i])) {
      list.add(selectedCountry.neighbors[i]);
    }
  }
  // Convert to array.
  return list.toArray(new Country[list.size()]);
}
boolean mayCountryAttackOther(Country attacker, Country defender) {
  // Can't attack same team.
  if (attacker.myTeamIndex == defender.myTeamIndex) { return false; }
  // Not enough dice to even attack, man.
  if (attacker.myDice <= 1) { return false; }
  // So few dice it'd be a guaranteed loss? Return false.
  if (attacker.myDice*6 <= defender.myDice) { return false; }
  // Sure, why not!
  return true;
}





