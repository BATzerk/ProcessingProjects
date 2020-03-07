
// ======== AI STUFF ========
class AI
{
  int myTeamIndex;

  AI(int team) {
    myTeamIndex = team;
  }

  void executeNextStep() {
    isAIExecutingTurn = true;

    Country[] selectableCountries = getSelectableCountries();

    boolean didDoAnAttack = false;
    for (int i=0; i<selectableCountries.length; i++) {
      int chosenCountry = (i + turnCount) % selectableCountries.length;
      setSelectedCountryIndex(selectableCountries[chosenCountry].ID);
      // Pick a random country to attack.
      Country[] attackableCountries = getAttackableCountriesWithAttackAdvantage();
      // We have countries to attack! Do attack!
      if (attackableCountries.length > 0) {
        Country selectedCountry = countries[selectedCountryIndex];
        Country defendingCountry = attackableCountries[floor(random(0,attackableCountries.length))];
        countryAttackOther(selectedCountry, defendingCountry);
        didDoAnAttack = true;
        break;
      }
    }
    if (!didDoAnAttack || isGameOver) {
      startNextPlayerTurn();
      return;
    }
  
    // Plan when to do next step. NOTE: FRAGILE! Timer runs concurrently with battle timer. IDEALLY, we'd only have ONE timer. It's "timeWhenNextStep", and when it's time, it'd call a function that handles what to do.
    timeWhenNextAIStep = currTime + (isBattleMode ? 3.0 : 0.5);
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
