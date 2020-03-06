static class Vector2Int {
  int x, y;
  Vector2Int (int x, int y) {
    this.x = x;
    this.y = y;
  }

  void add(Vector2Int op) {
    x += op.x;
    y += op.y;
  }

  static Vector2Int add(Vector2Int a, Vector2Int b) {
    return new Vector2Int(a.x + b.x, a.y + b.y);
  }
  
  public String toString() {
    return this.x + ", " + this.y;
  }
}
