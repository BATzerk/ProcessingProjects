// ======== PLAYER SELECT ========
final int AI_DIFFICULTY_EASY = 0;
final int AI_DIFFICULTY_NORMAL = 1;
final int AI_DIFFICULTY_HARD = 2;
final int MAX_PLAYERS = 8;

boolean isPlayerSelectScreen = !MOVIE_MODE;
int setupHumanCount = 1;
int setupAICount = 3;
int setupAIDifficulty = AI_DIFFICULTY_NORMAL;

final float PLAYER_SELECT_PANEL_WIDTH = 430;
final float PLAYER_SELECT_PANEL_HEIGHT = 410;
final float PLAYER_SELECT_BUTTON_HEIGHT = 42;
final float PLAYER_SELECT_BUTTON_RADIUS = 6;

void drawPlayerSelectScreen() {
  drawPlayerSelectBackground();

  float panelX = (width - PLAYER_SELECT_PANEL_WIDTH) / 2;
  float panelY = (height - PLAYER_SELECT_PANEL_HEIGHT) / 2;

  pushStyle();
  rectMode(CORNER);
  textAlign(CENTER, CENTER);
  noStroke();
  fill(0, 110);
  rect(panelX + 5, panelY + 7, PLAYER_SELECT_PANEL_WIDTH, PLAYER_SELECT_PANEL_HEIGHT, 9);
  fill(0, 150);
  rect(panelX, panelY, PLAYER_SELECT_PANEL_WIDTH, PLAYER_SELECT_PANEL_HEIGHT, 8);
  stroke(255, 80);
  strokeWeight(1.5);
  noFill();
  rect(panelX + 1, panelY + 1, PLAYER_SELECT_PANEL_WIDTH - 2, PLAYER_SELECT_PANEL_HEIGHT - 2, 8);

  fill(255);
  textSize(38);
  text("BATTLE DICE", width / 2, panelY + 50);

  drawPlayerSelectStepper("Humans", setupHumanCount, panelX + 55, panelY + 102);
  drawPlayerSelectStepper("AIs", setupAICount, panelX + 55, panelY + 164);

  fill(255, 220);
  textSize(18);
  text("AI Difficulty", width / 2, panelY + 226);
  drawDifficultyButton(AI_DIFFICULTY_EASY, "Easy", panelX + 48, panelY + 250, 104, PLAYER_SELECT_BUTTON_HEIGHT);
  drawDifficultyButton(AI_DIFFICULTY_NORMAL, "Normal", panelX + 163, panelY + 250, 104, PLAYER_SELECT_BUTTON_HEIGHT);
  drawDifficultyButton(AI_DIFFICULTY_HARD, "Hard", panelX + 278, panelY + 250, 104, PLAYER_SELECT_BUTTON_HEIGHT);

  drawPlayerSelectSwatches(width / 2, panelY + 322);
  fill(255, 230);
  textSize(16);
  text("Total players: " + getSetupPlayerCount(), width / 2, panelY + 347);

  drawPlayerSelectButton("START GAME", panelX + 110, panelY + 368, 210, PLAYER_SELECT_BUTTON_HEIGHT, true);
  popStyle();
}

void drawPlayerSelectBackground() {
  pushStyle();
  noStroke();
  for (int y = 0; y < height; y += 24) {
    fill(map(y, 0, height, 150, 165), 150, map(y, 0, height, 150, 95));
    rect(0, y, width, 24);
  }
  fill(0, 50);
  for (int x = -20; x < width + 40; x += 58) {
    for (int y = -20; y < height + 40; y += 50) {
      ellipse(x + ((y / 50) % 2) * 29, y, 10, 10);
    }
  }
  popStyle();
}

void drawPlayerSelectStepper(String label, int value, float x, float y) {
  fill(255, 230);
  textSize(20);
  textAlign(LEFT, CENTER);
  text(label, x, y + PLAYER_SELECT_BUTTON_HEIGHT / 2);
  textAlign(CENTER, CENTER);

  drawPlayerSelectButton("-", x + 190, y, 46, PLAYER_SELECT_BUTTON_HEIGHT, true);
  fill(255);
  textSize(26);
  text(value, x + 263, y + PLAYER_SELECT_BUTTON_HEIGHT / 2);
  drawPlayerSelectButton("+", x + 292, y, 46, PLAYER_SELECT_BUTTON_HEIGHT, true);
}

void drawDifficultyButton(int difficulty, String label, float x, float y, float w, float h) {
  drawPlayerSelectButton(label, x, y, w, h, setupAIDifficulty == difficulty);
}

void drawPlayerSelectButton(String label, float x, float y, float w, float h, boolean isSelected) {
  boolean isHovered = isMouseOverRect(x, y, w, h);
  noStroke();
  fill(0, 90);
  rect(x + 3, y + 4, w, h, PLAYER_SELECT_BUTTON_RADIUS);
  fill(isSelected ? color(42, 170, isHovered ? 255 : 230) : color(0, 0, isHovered ? 88 : 62));
  rect(x, y, w, h, PLAYER_SELECT_BUTTON_RADIUS);
  stroke(255, isHovered || isSelected ? 220 : 105);
  strokeWeight(isSelected ? 2.5 : 1.5);
  noFill();
  rect(x + 1, y + 1, w - 2, h - 2, PLAYER_SELECT_BUTTON_RADIUS);
  fill(isSelected ? 0 : 255);
  textSize(17);
  text(label, x + w / 2, y + h / 2);
}

void drawPlayerSelectSwatches(float centerX, float y) {
  float totalWidth = getSetupPlayerCount() * 25 - 7;
  float x = centerX - totalWidth / 2;
  for (int i = 0; i < getSetupPlayerCount(); i++) {
    fill((i * 255 / getSetupPlayerCount() + 65) % 255, 122, 255);
    noStroke();
    rect(x + i * 25, y, 18, 18, 4);
  }
}

void handlePlayerSelectMousePressed() {
  float panelX = (width - PLAYER_SELECT_PANEL_WIDTH) / 2;
  float panelY = (height - PLAYER_SELECT_PANEL_HEIGHT) / 2;

  if (isMouseOverRect(panelX + 245, panelY + 102, 46, PLAYER_SELECT_BUTTON_HEIGHT)) {
    changeSetupHumanCount(-1);
  } else if (isMouseOverRect(panelX + 347, panelY + 102, 46, PLAYER_SELECT_BUTTON_HEIGHT)) {
    changeSetupHumanCount(1);
  } else if (isMouseOverRect(panelX + 245, panelY + 164, 46, PLAYER_SELECT_BUTTON_HEIGHT)) {
    changeSetupAICount(-1);
  } else if (isMouseOverRect(panelX + 347, panelY + 164, 46, PLAYER_SELECT_BUTTON_HEIGHT)) {
    changeSetupAICount(1);
  } else if (isMouseOverRect(panelX + 48, panelY + 250, 104, PLAYER_SELECT_BUTTON_HEIGHT)) {
    setupAIDifficulty = AI_DIFFICULTY_EASY;
  } else if (isMouseOverRect(panelX + 163, panelY + 250, 104, PLAYER_SELECT_BUTTON_HEIGHT)) {
    setupAIDifficulty = AI_DIFFICULTY_NORMAL;
  } else if (isMouseOverRect(panelX + 278, panelY + 250, 104, PLAYER_SELECT_BUTTON_HEIGHT)) {
    setupAIDifficulty = AI_DIFFICULTY_HARD;
  } else if (isMouseOverRect(panelX + 110, panelY + 368, 210, PLAYER_SELECT_BUTTON_HEIGHT)) {
    startGameFromPlayerSelect();
  }
}

void handlePlayerSelectKeyPressed() {
  if (keyCode == ENTER) {
    startGameFromPlayerSelect();
  }
}

void changeSetupHumanCount(int delta) {
  setupHumanCount = constrain(setupHumanCount + delta, 0, MAX_PLAYERS);
  keepSetupPlayerCountsValid(true);
}

void changeSetupAICount(int delta) {
  setupAICount = constrain(setupAICount + delta, 0, MAX_PLAYERS);
  keepSetupPlayerCountsValid(false);
}

void keepSetupPlayerCountsValid(boolean preferHumans) {
  if (getSetupPlayerCount() < 2) {
    if (preferHumans) {
      setupAICount = 2 - setupHumanCount;
    } else {
      setupHumanCount = 2 - setupAICount;
    }
  }
  if (getSetupPlayerCount() > MAX_PLAYERS) {
    if (preferHumans) {
      setupAICount = MAX_PLAYERS - setupHumanCount;
    } else {
      setupHumanCount = MAX_PLAYERS - setupAICount;
    }
  }
}

void startGameFromPlayerSelect() {
  NUM_PLAYERS = getSetupPlayerCount();
  isPlayerSelectScreen = false;
  startNewGame();
}

int getSetupPlayerCount() {
  return setupHumanCount + setupAICount;
}

boolean isPlayerHumanControlled(int playerIndex) {
  return !MOVIE_MODE && playerIndex < setupHumanCount;
}

AI createAIForTeam(int teamIndex) {
  return new AI(teamIndex, setupAIDifficulty);
}

String getAIDifficultyName(int difficulty) {
  switch (difficulty) {
    case AI_DIFFICULTY_EASY: return "Easy";
    case AI_DIFFICULTY_HARD: return "Hard";
    default: return "Normal";
  }
}

boolean isMouseOverRect(float x, float y, float w, float h) {
  return mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h;
}
