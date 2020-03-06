// gridFunctions


boolean doesCardFitInLocation(int col,int row, Card card) {
  Point[] footprints;
  if (row%2==0) footprints = card.footprintsE;
  else footprints = card.footprintsO;
  for (int i=0; i<footprints.length; i++) {
    if (getGridSpaceAt(col+footprints[i].x,row+footprints[i].y) == null) return false;
    if (!getGridSpaceAt(col+footprints[i].x,row+footprints[i].y).isPlayableSpace) return false;
    if (getGridSpaceAt(col+footprints[i].x,row+footprints[i].y).myCard!=null && getGridSpaceAt(col+footprints[i].x,row+footprints[i].y).myCard!=card) return false;
  }
  return true;
}
boolean doFootprintsFitInLocation(int col,int row, Point[] footprints) {
  for (int i=0; i<footprints.length; i++) {
    if (getGridSpaceAt(col+footprints[i].x,row+footprints[i].y) == null) return false;
    if (!getGridSpaceAt(col+footprints[i].x,row+footprints[i].y).isPlayableSpace) return false;
    if (getGridSpaceAt(col+footprints[i].x,row+footprints[i].y).myCard != null) return false;
  }
  return true;
}


GridSpace getGridSpaceAt(int col,int row) {
  if (col<0 || row<0  ||  col>=cols || row >= rows) {
    return null;
  }
  return gridSpaces[col][row];
}
