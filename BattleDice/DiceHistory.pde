boolean showDiceHistoryGraph = false;
ArrayList<int[]> diceHistoryByTurn = new ArrayList<int[]>();
ArrayList<Integer> diceHistoryTurnNumbers = new ArrayList<Integer>();

final float DICE_HISTORY_GRAPH_MARGIN = 34;
final float DICE_HISTORY_GRAPH_LABEL_WIDTH = 76;
final float DICE_HISTORY_GRAPH_LABEL_HEIGHT = 34;
final float DICE_HISTORY_GRAPH_PADDING = 18;
final float DICE_HISTORY_GRAPH_DOT_RADIUS = 4;

void resetDiceHistory() {
  setDiceHistoryGraphVisible(false);
  diceHistoryByTurn.clear();
  diceHistoryTurnNumbers.clear();
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
    text(getPlayerName(i) + " " + getPlayerDiceTotal(i), x + 18, rowY);
  }
}
