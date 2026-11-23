#!/usr/bin/env python3
"""List the CSP build, track and cars an Assetto Corsa server asks for. Downloads nothing."""
import argparse
import json
import os
import urllib.request

ap = argparse.ArgumentParser(description=__doc__)
ap.add_argument("server", help="IP:HTTP_PORT, as shown in Content Manager")
ap.add_argument("--cars", help="content/cars folder, to list only missing cars")
a = ap.parse_args()
with urllib.request.urlopen(f"http://{a.server}/api/details", timeout=15) as r:
    d = json.load(r)
print("Server:", d.get("name"))
parts = str(d.get("track", "")).split("/")
print("Track: ", parts[-1], "| CSP build:", parts[1] if parts[0] == "csp" and len(parts) > 1 else "not stated")
links = (d.get("content") or {}).get("cars") or {}
for car in sorted(set(d.get("cars") or []) | set(links)):
    if a.cars and os.path.isdir(os.path.join(a.cars, car)):
        continue
    print(car, (links.get(car) or {}).get("url") or "(no link published)")
