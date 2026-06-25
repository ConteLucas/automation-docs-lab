#!/usr/bin/env python3
"""Wrapper — implementação em automation-learn/generate-ddt-drawio.py"""
from __future__ import annotations

import runpy
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
runpy.run_path(str(ROOT / "generate-ddt-drawio.py"), run_name="__main__")
