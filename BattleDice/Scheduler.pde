void scheduleAction(int action, float delay) {
  scheduledAction = action;
  timeWhenScheduledAction = currTime + delay;
}

void clearScheduledAction() {
  scheduledAction = SCHEDULED_ACTION_NONE;
}

void runDueScheduledAction() {
  if (scheduledAction == SCHEDULED_ACTION_NONE || currTime <= timeWhenScheduledAction) {
    return;
  }

  int action = scheduledAction;
  if (action == SCHEDULED_ACTION_AI_STEP) {
    runScheduledAIStep();
  }
}

void runScheduledAIStep() {
  if (isAITurnMode() && botPlayers[currPlayerIndex] != null) {
    clearScheduledAction();
    botPlayers[currPlayerIndex].executeNextStep();
  } else if (!isBattleMode() && !isMigrationMode()) {
    clearScheduledAction();
  }
}
