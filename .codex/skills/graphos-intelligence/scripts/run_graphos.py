#!/usr/bin/env python3
"""Portable entry point for the repository GraphOS engine."""
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[4]
runpy.run_path(str(ROOT / ".codex" / "graphos.py"), run_name="__main__")
