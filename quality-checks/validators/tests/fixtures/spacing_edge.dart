// Regression fixture for token_lint: bare `width`/`height` identifiers, comparisons,
// and return values are NOT off-grid spacing and must produce ZERO findings.
int columnsFor(double width) {
  if (width >= 840) return 3; // 3 columns, not a dimension
  if (width >= 600) return 2;
  return 1;
}

double clampHeight(double height) => height > 999 ? 999 : height;

int spanW(int columns) => columns * 2; // arithmetic, not a style literal
