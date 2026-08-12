"""Test configuration."""

import sys
from pathlib import Path

API_ROOT = Path(__file__).resolve().parents[1]
REPOSITORY_ROOT = API_ROOT.parents[1]
SRC_ROOT = API_ROOT / "src"
GAMEPLAY_SRC_ROOT = REPOSITORY_ROOT / "packages" / "gameplay" / "src"

sys.path.insert(0, str(SRC_ROOT))
sys.path.insert(0, str(GAMEPLAY_SRC_ROOT))
