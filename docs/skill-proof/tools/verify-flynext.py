#!/usr/bin/env python3
"""Verify that both checked-in outputs match a fresh projection, without writing."""
import runpy
import sys
from pathlib import Path

if __name__ == "__main__":
    build = runpy.run_path(str(Path(__file__).with_name("build-flynext.py")))
    sys.exit(build["main"](check=True))
