#!/usr/bin/env python3
import os
import sys
import subprocess

def get_snapshots(path):
    home = os.path.expanduser("~")
    rel = os.path.relpath(path, home)
    snapdir = os.path.join(home, ".snapshots")
    versions = []
    for snap in sorted(os.listdir(snapdir)):
        snap_path = os.path.join(snapdir, snap, rel)
        if os.path.exists(snap_path):
            versions.append((snap, snap_path))
    return versions

def main():
    if len(sys.argv) < 2:
        sys.exit(1)
    target = sys.argv[1]
    versions = get_snapshots(target)
    if not versions:
        subprocess.run(["kdialog", "--error", "No versions found in .snapshots"])
        sys.exit(0)
    choices = [f"{snap} ({os.path.basename(path)})" for snap, path in versions]
    choice = subprocess.run(
        ["kdialog", "--menu", "Select version to open/restore"] + sum([[str(i), c] for i, c in enumerate(choices)], []),
        capture_output=True, text=True
    ).stdout.strip()
    if not choice:
        sys.exit(0)
    idx = int(choice)
    snap_name, snap_path = versions[idx]
    action = subprocess.run(
        ["kdialog", "--menu", "Action", "open", "Open", "restore", "Restore"],
        capture_output=True, text=True
    ).stdout.strip()
    if action == "open":
        subprocess.Popen(["xdg-open", snap_path])
    elif action == "restore":
        orig = target
        backup = orig + ".old"
        os.rename(orig, backup)
        subprocess.run(["cp", "-a", snap_path, orig])
        subprocess.run(["kdialog", "--msgbox", f"Restored {orig} from {snap_name}, previous version saved as {backup}"])
    else:
        sys.exit(0)

if __name__ == "__main__":
    main()
