#!/usr/bin/env bash
# Copyright 2026 R. Heller
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
cd "$(dirname "$0")/.."
exec python3 tool/fetch_runtimes.py "$@"
