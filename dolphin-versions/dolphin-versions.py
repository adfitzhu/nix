#!/usr/bin/env python3
import tkinter as tk
from tkinter import messagebox
from tkinter import ttk
import os
import sys
import datetime
import subprocess
import shutil

class VersionDialog(tk.Tk):
    def __init__(self, target_path):
        super().__init__()
        self.title("Select Version")
        self.selected_index = None
        self.selected_action = None
        self.geometry("340x300")
        self.target_path = target_path
        # Radio buttons for mode selection
        radio_frame = ttk.Frame(self)
        radio_frame.pack(pady=4)
        self.mode_var = tk.StringVar(value="unique")
        unique_radio = ttk.Radiobutton(radio_frame, text="Unique Snapshots", variable=self.mode_var, value="unique", command=self.on_mode_change)
        all_radio = ttk.Radiobutton(radio_frame, text="All Snapshots", variable=self.mode_var, value="all", command=self.on_mode_change)
        unique_radio.pack(side=tk.LEFT, padx=6)
        all_radio.pack(side=tk.LEFT, padx=6)
        # Column headers
        header_frame = ttk.Frame(self)
        header_frame.pack(pady=(4,0), fill=tk.X)
        tk.Label(header_frame, text="Modified", font=("Arial", 10, "bold"), width=8, anchor="center").pack(side=tk.LEFT, padx=(8,0))
        tk.Label(header_frame, text="Snapshot Date", font=("Arial", 10, "bold"), anchor="w").pack(side=tk.LEFT, padx=(40,0))
        # Single listbox with star spacing and alternating row colors
        frame = ttk.Frame(self)
        frame.pack(pady=2, fill=tk.BOTH, expand=True)
        self.listbox = tk.Listbox(frame, font=("Arial", 11), height=10, width=38)
        scrollbar = ttk.Scrollbar(frame, orient="vertical", command=self.listbox.yview)
        self.listbox.config(yscrollcommand=scrollbar.set)
        self.listbox.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        btn_frame = ttk.Frame(self)
        btn_frame.pack(pady=10)
        style = ttk.Style(self)
        style.configure("TButton", padding=4, font=("Arial", 10), width=9)
        open_btn = ttk.Button(btn_frame, text="Open", command=self.open_clicked, style="TButton")
        open_btn.pack(side=tk.LEFT, padx=8)
        restore_btn = ttk.Button(btn_frame, text="Restore", command=self.restore_clicked, style="TButton")
        restore_btn.pack(side=tk.LEFT, padx=8)
        self.versions = []
        self.reload_versions()
    def reload_versions(self):
        mode = self.mode_var.get()
        self.versions = get_snapshot_versions(self.target_path, mode)
        self.listbox.delete(0, tk.END)
        if not self.versions:
            self.versions = [{'display': "No snapshots found", 'path': None, 'is_unique': False}]
        # Use Arial font and pad with spaces for alignment
        for i, v in enumerate(self.versions):
            star = '★' if v.get('is_unique') else ' '
            label = f"   {star}          {v['display']}"  # 3 spaces before, 10 after star
            self.listbox.insert(tk.END, label)
            # Alternate row color
            if i % 2 == 0:
                self.listbox.itemconfig(i, bg="#f0f0f0")
            else:
                self.listbox.itemconfig(i, bg="#e0e6f8")
    def on_mode_change(self):
        self.reload_versions()
    def open_clicked(self):
        sel = self.listbox.curselection()
        if sel:
            idx = sel[0]
            snap_path = self.versions[idx]['path']
            if snap_path:
                try:
                    subprocess.Popen(["xdg-open", snap_path])
                except Exception as e:
                    messagebox.showerror("Error", f"Failed to open file: {e}")
            self.destroy()
    def restore_clicked(self):
        sel = self.listbox.curselection()
        if sel:
            idx = sel[0]
            snap_path = self.versions[idx]['path']
            if snap_path:
                try:
                    orig = self.target_path
                    stat = os.stat(orig)
                    mtime = datetime.datetime.fromtimestamp(stat.st_mtime)
                    base, ext = os.path.splitext(orig)
                    mtime_str = mtime.strftime('%Y%m%d-%H%M%S')
                    backup = f"{base}-{mtime_str}{ext}"
                    os.rename(orig, backup)
                    if os.path.isdir(snap_path):
                        shutil.copytree(snap_path, orig)
                    else:
                        shutil.copy2(snap_path, orig)
                    messagebox.showinfo("Restore", f"Restored from snapshot. Previous version saved as:\n{backup}")
                except Exception as e:
                    messagebox.showerror("Error", f"Failed to restore file: {e}")
            self.destroy()

def get_snapshot_versions(target_path, mode="unique"):
    snapdir = "/home/.snapshots"
    rel = os.path.relpath(target_path, "/home")
    if not os.path.isdir(snapdir):
        return []
    try:
        current_stat = os.stat(target_path)
        current_mtime = current_stat.st_mtime
    except Exception:
        current_mtime = None
    seen_mtimes = set()
    version_tuples = []
    for snap in sorted(os.listdir(snapdir)):
        snap_path = os.path.join(snapdir, snap, rel)
        if os.path.exists(snap_path):
            try:
                stat = os.stat(snap_path)
                mtime = stat.st_mtime
                if mtime == current_mtime:
                    continue
                is_unique = False
                if mode == "unique":
                    if mtime in seen_mtimes:
                        continue
                    seen_mtimes.add(mtime)
                    is_unique = True
                else:
                    if mtime not in seen_mtimes:
                        is_unique = True
                        seen_mtimes.add(mtime)
                version_tuples.append((mtime, snap_path, is_unique))
            except Exception:
                continue
    version_tuples.sort(reverse=True, key=lambda x: x[0])
    versions = []
    for mtime, snap_path, is_unique in version_tuples:
        dt = datetime.datetime.fromtimestamp(mtime)
        display = dt.strftime('%b %d %Y %-I:%M%p').replace('AM','am').replace('PM','pm')
        versions.append({'display': display, 'path': snap_path, 'is_unique': is_unique})
    return versions

def main():
    if len(sys.argv) < 2:
        messagebox.showerror("Error", "No file specified.")
        return
    target = sys.argv[1]
    app = VersionDialog(target)
    app.mainloop()

if __name__ == "__main__":
    main()
