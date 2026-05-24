import java.util.LinkedList;
import java.util.HashSet;
import java.util.Set;

final int BORDER_NORMAL = 0;
final int BORDER_ATTACKABLE = 1;
final int BORDER_HOVERED_ATTACK = 2;
final float COUNTRY_SHUDDER_DURATION = 0.45;
final float COUNTRY_SHUDDER_AMOUNT = 5;
final float COUNTRY_CAPTURE_HIGHLIGHT_DURATION = 1.0;
final float COUNTRY_DIE_RADIUS_SCALE = 0.65;

class Country
{
  int myTeamIndex = -1;
  int myDice = 0;
  LinkedList<Cell> cells;
  Country[] neighbors;
  int ID;
  float displayOffsetY; // for raising up selected and battling countries.
  float shudderStartTime = -COUNTRY_SHUDDER_DURATION;
  float captureHighlightStartTime = -COUNTRY_CAPTURE_HIGHLIGHT_DURATION;

  Country(int index, Cell startingCell) {
    this.ID = index;
    this.cells = new LinkedList<Cell>();
    this.addCell(startingCell);
  }

  void startShudder() {
    shudderStartTime = currTime;
  }

  void startCaptureHighlight() {
    captureHighlightStartTime = currTime;
  }

  float shudderProgress() {
    return constrain((currTime - shudderStartTime) / COUNTRY_SHUDDER_DURATION, 0, 1);
  }

  float shudderStrength() {
    return (1 - shudderProgress()) * COUNTRY_SHUDDER_AMOUNT;
  }

  float shudderOffsetX() {
    return sin(currTime * 72) * shudderStrength();
  }

  float shudderOffsetY() {
    return cos(currTime * 91) * shudderStrength() * 0.65;
  }

  float captureHighlightAlpha() {
    float progress = constrain((currTime - captureHighlightStartTime) / COUNTRY_CAPTURE_HIGHLIGHT_DURATION, 0, 1);
    return (1 - easeInOut(progress)) * 185;
  }

  void addCell(Cell c) {
    c.setCountry(this);
    cells.add(c);
  }

  Cell getRandomEdgeCell() {
    return cells.get(floor(random(cells.size())));
  }

  boolean isNeighboring(Country op) {
    return isNeighboring(op.ID);
  }
  boolean isNeighboring(int id) {
    if (id < 0 || id == this.ID) return false;
    for (int i = 0; i < neighbors.length; i++) {
      if (neighbors[i].ID == id) {
        return true;
      }
    }
    return false;
  }

  void learnNeighbors() {
    Set<Integer> set = new HashSet<Integer>();
    for (int i = 0; i < cells.size (); i++) {
      for (int face = 0; face < NUM_FACES; face++) {
        Cell ncell = cells.get(i).getNeighbor(face);
        if (ncell != null && ncell.myCountry != null) {
          set.add(ncell.myCountry.ID);
        }
      }
    }
    set.remove(this.ID);
    this.neighbors = new Country[set.size()];
    int i = 0;
    for (int id : set) {
      neighbors[i] = countries[id];
      i++;
    }
  }

  void addNeighborsToSet(Set ids, Set checked) {
    checked.add(this.ID);
    ids.add(this.ID);
    for (int i = 0; i < this.neighbors.length; i++) {
      ids.add(this.neighbors[i].ID);
      if (!checked.contains(this.neighbors[i].ID)) {
        this.neighbors[i].addNeighborsToSet(ids, checked);
      }
    }
  }

  int countCountriesOnIsland() {
    Set<Integer> ids = new HashSet<Integer>();
    Set<Integer> checked = new HashSet<Integer>();
    this.addNeighborsToSet(ids, checked);
    return ids.size();
  }

  void findNeighborsInGroup(Set ids, Set checked) {
    checked.add(this.ID);
    ids.add(this.ID);
    for (int i = 0; i < this.neighbors.length; i++) {
      if (this.neighbors[i].myTeamIndex != this.myTeamIndex) {
        continue;
      }
      ids.add(this.neighbors[i].ID);
      if (!checked.contains(this.neighbors[i].ID)) {
        this.neighbors[i].findNeighborsInGroup(ids, checked);
      }
    }
  }

  int[] getMyCountryGroup() {
    Set<Integer> ids = new HashSet<Integer>();
    Set<Integer> checked = new HashSet<Integer>();
    this.findNeighborsInGroup(ids, checked);
    int[] ret = new int[ids.size()];
    int i = 0;
    for (int id : ids) {
      ret[i++] = id;
    }
    return ret;
  }

  color myColor() {
    boolean isInDanger =
      isCurrentPlayerHuman()
      && !isBattleMode
      && !isGameOver
      && selectedCountryIndex > -1
      && countries[selectedCountryIndex].myTeamIndex != this.myTeamIndex
      && isNeighboring(selectedCountryIndex);
    boolean canReceiveMigration =
      isCurrentPlayerHuman()
      && !isBattleMode
      && !isGameOver
      && selectedCountryIndex > -1
      && canMigrateDice(countries[selectedCountryIndex], this);

    color baseColor = myTeamIndex > -1 ? teamColor(myTeamIndex) : color(32, 34, 234);
    if (!isInDanger && !canReceiveMigration) {
      return baseColor;
    } else {
      float highlightAlpha = sinRange(currTime*0.008, 0.2, 0.5);//+ID
      color highlightColor = canReceiveMigration ? color(90, 120, 255) : (myTeamIndex>-1 ? color(teamHue(myTeamIndex), 90, 255) : color(255));
      return lerpColor(baseColor, highlightColor, highlightAlpha);
    }
  }

  PVector centerScreenPos() {
    PVector center = new PVector(0, 0);
    for (int i=0; i<cells.size (); i++) {
      Cell cell = (Cell) cells.get(i);
      center.add(cell.screenPos);
    }
    center.div(max(1, cells.size()));
    return center;
  }

  PVector dieScreenPos(int dieIndex) {
    return centeredDieCell(dieIndex).screenPos.copy();
  }

  Cell centeredDieCell(int dieIndex) {
    PVector center = centerScreenPos();
    Cell bestCell = (Cell) cells.get(0);
    float bestScore = Float.MAX_VALUE;

    for (int i=0; i<cells.size (); i++) {
      Cell cell = (Cell) cells.get(i);
      int closerCells = countCellsCloserToCenter(cell, center);
      if (closerCells != dieIndex) {
        continue;
      }

      float score = cell.screenPos.dist(center);
      if (score < bestScore) {
        bestCell = cell;
        bestScore = score;
      }
    }

    return bestCell;
  }

  int countCellsCloserToCenter(Cell candidate, PVector center) {
    int count = 0;
    float candidateDistance = candidate.screenPos.dist(center);
    for (int i=0; i<cells.size (); i++) {
      Cell cell = (Cell) cells.get(i);
      float distance = cell.screenPos.dist(center);
      if (
        distance < candidateDistance
        || (distance == candidateDistance && cellIndexTieBreaker(cell) < cellIndexTieBreaker(candidate))
      ) {
        count++;
      }
    }
    return count;
  }

  int cellIndexTieBreaker(Cell cell) {
    return cell.gridPos.y * GRID_WIDTH + cell.gridPos.x;
  }

  void drawMyCellsShapes() {
    pushMatrix();
    translate(shudderOffsetX(), displayOffsetY + shudderOffsetY());
    for (int i=0; i<cells.size (); i++) {
      Cell cell = (Cell) cells.get(i);
      drawHexagon(cell.screenPos);
    }
    popMatrix();
  }
  void drawMyCellsFill() {
    // Cells
    fill(myColor());
    noStroke();
    drawMyCellsShapes();
    if (isCountryHoveredAndInteractable(this)) {
      fill(255, 80);
      drawMyCellsShapes();
    }
    float captureAlpha = captureHighlightAlpha();
    if (captureAlpha > 0) {
      fill(255, captureAlpha);
      drawMyCellsShapes();
    }

    // Dice
    pushMatrix();
    translate(shudderOffsetX(), displayOffsetY + shudderOffsetY());
    fill(250);
    stroke(60);
    strokeWeight(1);
    for (int i=0; i<myDice; i++) {
      drawHexagon(dieScreenPos(i), tileRadius * COUNTRY_DIE_RADIUS_SCALE);
    }
    popMatrix();
  }
  void drawMyCellsShadow() {
    pushMatrix();
    translate(0, 6); // offset for shadow.
    fill(0, 40);
    noStroke();
    drawMyCellsShapes();
    popMatrix();
  }
  boolean isAttackableFromSelection() {
    return isCurrentPlayerHuman()
      && !isBattleMode
      && !isGameOver
      && selectedCountryIndex > -1
      && canActOnCountry(countries[selectedCountryIndex], this);
  }

  void drawNormalBorders() {
    drawBorders(BORDER_NORMAL);
  }

  void drawAttackableBorders() {
    if (isAttackableFromSelection()) {
      drawBorders(BORDER_ATTACKABLE);
    }
  }

  void drawHoveredAttackBorder() {
    if (isAttackableFromSelection() && isCountryHovered(this)) {
      drawBorders(BORDER_HOVERED_ATTACK);
    }
  }

  void drawBorders(int borderMode) {
    pushMatrix();
    translate(shudderOffsetX(), displayOffsetY + shudderOffsetY());
    color baseBorderColor = color(80);
    for (int i=0; i<cells.size (); i++) {
      Cell thisCell = (Cell) cells.get(i);
      for (int face=0; face<NUM_FACES; face++) {
        Cell otherCell = thisCell.getNeighbor(face);
        boolean isBorder = otherCell==null || thisCell.myCountry!=otherCell.myCountry;
        if (isBorder) {
          if (borderMode == BORDER_HOVERED_ATTACK) {
            stroke(teamHue(currPlayerIndex), 160, 255);
            strokeWeight(4.5);
          }
          else if (borderMode == BORDER_ATTACKABLE) {
            float wave = sinRange(
              currTime * 4
              - thisCell.screenPos.x * 0.008
              + thisCell.screenPos.y * 0.0099
              + face * 0.0,
              0, 1);
            color highlightBorderColorA = color(170);//color(teamHue(currPlayerIndex), 80, 255);
            color highlightBorderColorB = color(250);//color(teamHue(currPlayerIndex), 200, 255);
            stroke(lerpColor(highlightBorderColorA, highlightBorderColorB, wave));
            strokeWeight(3);
          }
          else {
            stroke(baseBorderColor);
            strokeWeight(2);
          }
          drawHexLine(thisCell.gridPos, face);
        }
      }
    }
    popMatrix();
  }
}

ArrayList<int[]> getCountryGroups(int teamIndex) {
  Set<Integer> counted = new HashSet<Integer>();
  ArrayList<int[]> groupList = new ArrayList<int[]>();
  for (int i = 0; i < countries.length; i++) {
    if (
      countries[i].myTeamIndex == teamIndex && // make sure it's the right team
      !counted.contains(i)                     // make sure we haven't checked it yet
      ) {
      int[] group = countries[i].getMyCountryGroup();
      for (int j = 0; j < group.length; j++) {
        counted.add(group[j]);
      }
      groupList.add(group);
    }
  }
  return groupList;
}
