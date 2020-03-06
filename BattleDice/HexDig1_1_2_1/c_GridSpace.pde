// c_GridSpace


class GridSpace {
  int x,y,z; // location in the hex grid
  Card myCard;
  boolean isPlayableSpace = true;
  boolean isRevealed;
  
  GridSpace(boolean IsPlayableSpace) {
    isPlayableSpace = IsPlayableSpace;
    isRevealed = false;
  }
  
}
