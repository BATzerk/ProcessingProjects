boolean showDiceHistoryGraph = false;
ArrayList<int[]> diceHistoryByTurn = new ArrayList<int[]>();
ArrayList<Integer> diceHistoryTurnNumbers = new ArrayList<Integer>();
ArrayList<int[]> superUnderdogVictoriesByTurn = new ArrayList<int[]>();
int[] playerSuperUnderdogVictories;

final float DICE_HISTORY_GRAPH_MARGIN = 34;
final float DICE_HISTORY_GRAPH_LABEL_WIDTH = 76;
final float DICE_HISTORY_GRAPH_LABEL_HEIGHT = 34;
final float DICE_HISTORY_GRAPH_PADDING = 18;
final float DICE_HISTORY_GRAPH_DOT_RADIUS = 4;
final float DICE_HISTORY_SUPER_UNDERDOG_MARKER_SIZE = 13;
final float DICE_HISTORY_SUPER_UNDERDOG_MARKER_GAP = 15;

void resetDiceHistory() {
  setDiceHistoryGraphVisible(false);
  diceHistoryByTurn.clear();
  diceHistoryTurnNumbers.clear();
  superUnderdogVictoriesByTurn.clear();
  playerSuperUnderdogVictories = new int[playerCount];
  recordDiceHistorySample();
}

void recordDiceHistorySample() {
  if (countries == null || countries.length == 0 || playerCount <= 0) {
    return;
  }

  int[] totals = new int[playerCount];
  for (int i = 0; i < playerCount; i++) {
    totals[i] = getPlayerDiceTotal(i);
  }
  diceHistoryByTurn.add(totals);
  diceHistoryTurnNumbers.add(turnCount);
  superUnderdogVictoriesByTurn.add(copyPlayerSuperUnderdogVictories());
}

int[] copyPlayerSuperUnderdogVictories() {
  if (playerSuperUnderdogVictories == null || playerSuperUnderdogVictories.length != playerCount) {
    playerSuperUnderdogVictories = new int[playerCount];
  }

  int[] totals = new int[playerCount];
  for (int i = 0; i < playerCount; i++) {
    totals[i] = playerSuperUnderdogVictories[i];
  }
  return totals;
}

void recordSuperUnderdogVictory(int playerIndex) {
  if (playerIndex < 0 || playerIndex >= playerCount) {
    return;
  }
  if (playerSuperUnderdogVictories == null || playerSuperUnderdogVictories.length != playerCount) {
    playerSuperUnderdogVictories = new int[playerCount];
  }

  playerSuperUnderdogVictories[playerIndex]++;
  updateCurrentSuperUnderdogHistorySample();
}

void updateCurrentSuperUnderdogHistorySample() {
  if (superUnderdogVictoriesByTurn.size() == 0) {
    return;
  }

  int lastIndex = superUnderdogVictoriesByTurn.size() - 1;
  if (diceHistoryTurnNumbers.get(lastIndex) == turnCount) {
    superUnderdogVictoriesByTurn.set(lastIndex, copyPlayerSuperUnderdogVictories());
  }
}

void toggleDiceHistoryGraph() {
  showDiceHistoryGraph = !showDiceHistoryGraph;
}

void setDiceHistoryGraphVisible(boolean isVisible) {
  showDiceHistoryGraph = isVisible;
}

void drawDiceHistoryGraph() {
  if (!showDiceHistoryGraph || diceHistoryByTurn.size() == 0) {
    return;
  }

  pushStyle();
  pushMatrix();

  float graphX = DICE_HISTORY_GRAPH_MARGIN;
  float graphY = ACTIVE_PLAYER_BANNER_HEIGHT + DICE_HISTORY_GRAPH_MARGIN;
  float graphW = width - DICE_HISTORY_GRAPH_MARGIN * 2;
  float graphH = height - graphY - DICE_HISTORY_GRAPH_MARGIN;
  float plotX = graphX + DICE_HISTORY_GRAPH_LABEL_WIDTH;
  float plotY = graphY + DICE_HISTORY_GRAPH_PADDING;
  float plotW = max(1, graphW - DICE_HISTORY_GRAPH_LABEL_WIDTH - DICE_HISTORY_GRAPH_PADDING);
  float plotH = max(1, graphH - DICE_HISTORY_GRAPH_LABEL_HEIGHT - DICE_HISTORY_GRAPH_PADDING * 2);
  int maxDice = max(1, getDiceHistoryMaxTotal());

  rectMode(CORNER);
  textAlign(CENTER, CENTER);
  textSize(14);
  noStroke();
  fill(0, 0, 0, 216);
  rect(graphX, graphY, graphW, graphH, 8);

  stroke(0, 0, 255, 60);
  scaledStrokeWeight(1);
  line(plotX, plotY, plotX, plotY + plotH);
  line(plotX, plotY + plotH, plotX + plotW, plotY + plotH);

  fill(0, 0, 255, 190);
  text(maxDice, graphX + DICE_HISTORY_GRAPH_LABEL_WIDTH / 2, plotY);
  text("0", graphX + DICE_HISTORY_GRAPH_LABEL_WIDTH / 2, plotY + plotH);
  text("turn " + diceHistoryTurnNumbers.get(diceHistoryTurnNumbers.size() - 1), plotX + plotW / 2, graphY + graphH - DICE_HISTORY_GRAPH_LABEL_HEIGHT / 2);

  for (int i = 0; i < playerCount; i++) {
    drawDiceHistoryPlayerLine(i, plotX, plotY, plotW, plotH, maxDice);
  }
  drawSuperUnderdogVictoryMarkers(plotX, plotY, plotW, plotH);

  drawDiceHistoryLegend(graphX + DICE_HISTORY_GRAPH_PADDING, graphY + DICE_HISTORY_GRAPH_PADDING);

  popMatrix();
  popStyle();
}

int getDiceHistoryMaxTotal() {
  int maxTotal = 1;
  for (int sampleIndex = 0; sampleIndex < diceHistoryByTurn.size(); sampleIndex++) {
    int[] totals = diceHistoryByTurn.get(sampleIndex);
    for (int playerIndex = 0; playerIndex < totals.length; playerIndex++) {
      maxTotal = max(maxTotal, totals[playerIndex]);
    }
  }
  return maxTotal;
}

void drawDiceHistoryPlayerLine(int playerIndex, float plotX, float plotY, float plotW, float plotH, int maxDice) {
  if (diceHistoryByTurn.size() == 0) {
    return;
  }

  stroke(teamColor(playerIndex));
  scaledStrokeWeight(playerIndex == currPlayerIndex ? 3 : 2);
  noFill();
  beginShape();
  for (int sampleIndex = 0; sampleIndex < diceHistoryByTurn.size(); sampleIndex++) {
    int[] totals = diceHistoryByTurn.get(sampleIndex);
    float x = getDiceHistorySampleX(sampleIndex, plotX, plotW);
    float y = getDiceHistoryTotalY(totals[playerIndex], plotY, plotH, maxDice);
    vertex(x, y);
  }
  endShape();

  fill(teamColor(playerIndex));
  noStroke();
  for (int sampleIndex = 0; sampleIndex < diceHistoryByTurn.size(); sampleIndex++) {
    int[] totals = diceHistoryByTurn.get(sampleIndex);
    float x = getDiceHistorySampleX(sampleIndex, plotX, plotW);
    float y = getDiceHistoryTotalY(totals[playerIndex], plotY, plotH, maxDice);
    ellipse(x, y, DICE_HISTORY_GRAPH_DOT_RADIUS * 2, DICE_HISTORY_GRAPH_DOT_RADIUS * 2);
  }
}

void drawSuperUnderdogVictoryMarkers(float plotX, float plotY, float plotW, float plotH) {
  if (superUnderdogVictoriesByTurn.size() == 0) {
    return;
  }

  textAlign(CENTER, CENTER);
  textSize(12);
  for (int sampleIndex = 0; sampleIndex < superUnderdogVictoriesByTurn.size(); sampleIndex++) {
    int[] totals = superUnderdogVictoriesByTurn.get(sampleIndex);
    int[] previousTotals = sampleIndex > 0
      ? superUnderdogVictoriesByTurn.get(sampleIndex - 1)
      : new int[playerCount];
    int markerIndex = 0;
    for (int playerIndex = 0; playerIndex < totals.length; playerIndex++) {
      int previousTotal = playerIndex < previousTotals.length ? previousTotals[playerIndex] : 0;
      int victoriesThisSample = totals[playerIndex] - previousTotal;
      for (int i = 0; i < victoriesThisSample; i++) {
        float x = getDiceHistorySampleX(sampleIndex, plotX, plotW);
        float y = plotY + plotH - 12 - markerIndex * DICE_HISTORY_SUPER_UNDERDOG_MARKER_GAP;
        drawSuperUnderdogVictoryMarker(x, y, teamColor(playerIndex));
        markerIndex++;
      }
    }
  }
}

void drawSuperUnderdogVictoryMarker(float x, float y, color markerColor) {
  pushMatrix();
  translate(x, y);
  stroke(0, 0, 0, 160);
  scaledStrokeWeight(1.5);
  fill(markerColor);
  beginShape();
  for (int i = 0; i < 10; i++) {
    float radius = i % 2 == 0
      ? DICE_HISTORY_SUPER_UNDERDOG_MARKER_SIZE * 0.55
      : DICE_HISTORY_SUPER_UNDERDOG_MARKER_SIZE * 0.23;
    float angle = -HALF_PI + i * TWO_PI / 10;
    vertex(cos(angle) * radius, sin(angle) * radius);
  }
  endShape(CLOSE);
  fill(255);
  noStroke();
  text("S", 0, 0);
  popMatrix();
}

float getDiceHistorySampleX(int sampleIndex, float plotX, float plotW) {
  if (diceHistoryByTurn.size() <= 1) {
    return plotX;
  }
  return plotX + plotW * sampleIndex / (diceHistoryByTurn.size() - 1);
}

float getDiceHistoryTotalY(int total, float plotY, float plotH, int maxDice) {
  return plotY + plotH - plotH * total / max(1, maxDice);
}

void drawDiceHistoryLegend(float x, float y) {
  textAlign(LEFT, CENTER);
  textSize(13);
  for (int i = 0; i < playerCount; i++) {
    float rowY = y + i * 19;
    fill(teamColor(i));
    noStroke();
    ellipse(x + 6, rowY, 9, 9);
    fill(0, 0, 255, 210);
    text(getPlayerName(i) + " " + getPlayerDiceTotal(i) + "  S " + getPlayerSuperUnderdogVictoryTotal(i), x + 18, rowY);
  }
}

int getPlayerSuperUnderdogVictoryTotal(int playerIndex) {
  if (playerSuperUnderdogVictories == null
    || playerIndex < 0
    || playerIndex >= playerSuperUnderdogVictories.length) {
    return 0;
  }
  return playerSuperUnderdogVictories[playerIndex];
}
