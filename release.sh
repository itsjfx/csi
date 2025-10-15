#!/usr/bin/env bash

set -eu -o pipefail

uv run python -m build
uv run twine upload dist/*
