#!/usr/bin/env python3
"""
bind_tool.py — read and edit Hyprland Lua binds for the Quickshell shortcut GUI.

Subcommands:
  read                        parse binds.lua -> JSON on stdout
  setkey <id> <mods> <key>    change one bind's key/mods, write back
  workspace <n>               set workspace count (1..10)

Bind identity: each editable bind gets a stable id derived from its action, so
the GUI can reference it across reads. Parsing is line-oriented and targeted at
the patterns actually used in this file (mainMod .. " + KEY"), not a general
Lua parser — that keeps it robust and predictable.
"""

import sys, json, re, os

HOME = os.path.expanduser("~")
BINDS_PATH = os.environ.get("HYPR_BINDS",
    os.path.join(HOME, ".config", "hypr", "components", "binds.lua"))

# --- action -> friendly label + group ---------------------------------------
# Maps the dispatcher call to a human label and a group bucket.
def classify(action):
    a = action.strip()
    # quickshell global shortcuts
    m = re.search(r'global\("quickshell:(\w+)"\)', a)
    if m:
        name = m.group(1)
        if name.startswith("cat_"):
            return ("Category " + name[4:], "quickshell")
        label = {"launcher": "App launcher",
                 "controlpanel": "Control panel"}.get(name, name.capitalize())
        return (label, "quickshell")
    # programs
    if "exec_cmd(terminal)" in a: return ("Terminal", "programs")
    if "exec_cmd(fileManager)" in a: return ("File manager", "programs")
    if "exec_cmd(menu)" in a: return ("App menu", "programs")
    if "hyprshutdown" in a: return ("Power menu", "system")
    if "hyprshot -m window" in a: return ("Screenshot (window)", "system")
    if "hyprshot -m region" in a: return ("Screenshot (region)", "system")
    # window ops
    if "window.close()" in a: return ("Close window", "hyprland")
    if "window.float" in a: return ("Toggle float", "hyprland")
    if "window.pseudo" in a: return ("Pseudo", "hyprland")
    if 'layout("togglesplit")' in a: return ("Toggle split", "hyprland")
    if "toggle_special" in a: return ("Scratchpad", "hyprland")
    # focus directions
    m = re.search(r'focus\(\{\s*direction\s*=\s*"(\w+)"', a)
    if m: return ("Focus " + m.group(1), "hyprland")
    # --- fallback: recognize the shape, derive a label so ANY bind shows ---
    # exec_cmd("some command") -> label from the command's first word
    m = re.search(r'exec_cmd\(\s*"([^"]+)"', a)
    if m:
        cmd = m.group(1).strip()
        first = cmd.split()[0] if cmd else "command"
        base = first.split("/")[-1]           # strip path
        return (base, "programs")
    # exec_cmd(variable) -> use the variable name
    m = re.search(r'exec_cmd\(\s*(\w+)\s*\)', a)
    if m:
        return (m.group(1), "programs")
    # any other window.* / workspace.* dispatcher -> label from the call
    m = re.search(r'hl\.dsp\.(\w+)\.(\w+)', a)
    if m:
        label = (m.group(2).replace("_", " ")).capitalize()
        return (label, "hyprland")
    m = re.search(r'hl\.dsp\.(\w+)', a)
    if m:
        return (m.group(1).capitalize(), "hyprland")
    return (None, None)

# --- read -------------------------------------------------------------------
# Matches:  hl.bind(mainMod .. " + KEY", <action>)  possibly with `local x =`
BIND_RE = re.compile(
    r'hl\.bind\(\s*mainMod\s*\.\.\s*"\s*\+\s*([^"]+?)"\s*,\s*(.+?)\)\s*(?:--.*)?$'
)
# also plain-string binds:  hl.bind("KEY", <action>, {opts})  (media/print)
PLAIN_RE = re.compile(
    r'hl\.bind\(\s*"([^"]+)"\s*,\s*(.+?)\)\s*(?:,\s*\{[^}]*\}\s*)?\)?\s*(?:--.*)?$'
)

def parse_key_and_mods(keystr):
    # keystr like 'SHIFT + S' or 'RETURN' or 'left'
    parts = [p.strip() for p in keystr.split("+")]
    mods = []
    key = None
    for p in parts:
        up = p.upper()
        if up in ("SHIFT", "CTRL", "CONTROL", "ALT", "SUPER"):
            mods.append("SHIFT" if up == "SHIFT"
                        else "CTRL" if up in ("CTRL", "CONTROL")
                        else "ALT" if up == "ALT" else "SUPER")
        else:
            key = p
    return mods, key

def read():
    if not os.path.exists(BINDS_PATH):
        print(json.dumps({
            "groups": {"hyprland": [], "quickshell": [], "programs": [], "system": []},
            "workspace": {"count": 5},
            "error": "binds file not found: " + BINDS_PATH
        }))
        return
    with open(BINDS_PATH, "r", encoding="utf-8") as f:
        lines = f.readlines()

    groups = {"hyprland": [], "quickshell": [], "programs": [], "system": []}
    workspace_count = 5

    # detect workspace count: highest value in azerty_workspace_keys table
    in_table = False
    ws_vals = []
    for ln in lines:
        if "azerty_workspace_keys" in ln and "{" in ln:
            in_table = True; continue
        if in_table:
            if "}" in ln:
                in_table = False
            m = re.search(r'\]\s*=\s*(\d+)', ln)
            if m: ws_vals.append(int(m.group(1)))
    if ws_vals:
        workspace_count = max(ws_vals)

    for idx, ln in enumerate(lines):
        s = ln.strip()
        if not s.startswith("hl.bind") and "hl.bind" not in s:
            continue
        # skip the loop-generated and mouse binds for editing
        if "mouse" in s or ".. key" in s or ".. \" + \" .. key" in s:
            continue

        m = BIND_RE.search(s)
        if m:
            keystr, action = m.group(1), m.group(2)
            label, group = classify(action)
            if label is None:
                continue  # unknown/complex — skip from editable list
            mods, key = parse_key_and_mods(keystr)
            has_super = True  # mainMod is SUPER by definition here
            combo = next((x for x in mods if x in ("SHIFT", "CTRL", "ALT")), "")
            bind_id = label.lower().replace(" ", "_").replace("(", "").replace(")", "")
            bind_id = bind_id + "_L" + str(idx)   # ensure uniqueness per line
            groups[group].append({
                "id": bind_id,
                "label": label,
                "line": idx,
                "super": has_super,
                "combo": combo,
                "key": key or "",
                "editable": True,
            })
            continue

        # plain-string binds: XF86 media (read-only) OR super-less editable binds
        mp = PLAIN_RE.search(s)
        if mp:
            keystr, action = mp.group(1), mp.group(2)
            if keystr.startswith("XF86"):
                label = keystr.replace("XF86", "")
                groups["system"].append({
                    "id": "xf86_" + label.lower(),
                    "label": label, "line": idx,
                    "super": False, "combo": "", "key": keystr,
                    "editable": False,
                })
            else:
                # a super-less bind (e.g. after unchecking Super) — classify it
                label, group = classify(action)
                if label is None:
                    continue
                mods, key = parse_key_and_mods(keystr)
                combo = next((x for x in mods if x in ("SHIFT", "CTRL", "ALT")), "")
                bind_id = label.lower().replace(" ", "_").replace("(", "").replace(")", "")
                bind_id = bind_id + "_L" + str(idx)
                groups[group].append({
                    "id": bind_id, "label": label, "line": idx,
                    "super": False, "combo": combo, "key": key or "",
                    "editable": True,
                })

    out = {"groups": groups, "workspace": {"count": workspace_count}}
    print(json.dumps(out, indent=2))

# --- setkey -----------------------------------------------------------------
def setkey(bind_id, mods_csv, key):
    with open(BINDS_PATH, "r", encoding="utf-8") as f:
        lines = f.readlines()

    mods = [m for m in mods_csv.split(",") if m]
    has_super = "SUPER" in mods
    non_super = [m for m in mods if m != "SUPER"]

    # find the bind's line
    data = json.loads(_read_to_str())
    target_line = None
    for g in data["groups"].values():
        for b in g:
            if b["id"] == bind_id and b["editable"]:
                target_line = b["line"]
                break
    if target_line is None:
        print(json.dumps({"ok": False, "error": "bind not found: " + bind_id}))
        return

    ln = lines[target_line]

    # Build the new key expression. With super -> use mainMod .. " + ...".
    # Without super -> plain string "MODS + KEY".
    if has_super:
        if non_super:
            new_expr = 'mainMod .. " + %s + %s"' % (" + ".join(non_super), key)
        else:
            new_expr = 'mainMod .. " + %s"' % key
    else:
        combined = " + ".join(non_super + [key]) if non_super else key
        new_expr = '"%s"' % combined

    # Replace the FIRST argument of hl.bind(...) — whether it was
    # `mainMod .. "..."` or a plain "...". Match up to the first top-level comma.
    m = re.match(r'^(\s*)(local\s+\w+\s*=\s*)?(hl\.bind\()(.*)$', ln)
    if not m:
        print(json.dumps({"ok": False, "error": "unparseable line"}))
        return
    indent, localpart, callpart, rest = m.groups()
    localpart = localpart or ""
    # rest starts after 'hl.bind(' — find the first argument (up to the comma
    # that separates it from the dispatcher). The first arg is either
    # mainMod .. "..."  or  "...".
    # Split on the first comma that's not inside quotes.
    arg1, sep, arg2 = _split_first_arg(rest)
    new_ln = "%s%s%s%s,%s" % (indent, localpart, callpart, new_expr, arg2)
    if not new_ln.endswith("\n"):
        new_ln += "\n"
    lines[target_line] = new_ln
    with open(BINDS_PATH, "w", encoding="utf-8") as f:
        f.writelines(lines)
    print(json.dumps({"ok": True, "id": bind_id, "super": has_super,
        "expr": new_expr}))

def _split_first_arg(s):
    """Split 'ARG1, REST...' on the first top-level comma (not inside quotes)."""
    depth = 0
    in_str = False
    esc = False
    for i, ch in enumerate(s):
        if esc:
            esc = False; continue
        if ch == "\\":
            esc = True; continue
        if ch == '"':
            in_str = not in_str; continue
        if in_str:
            continue
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        elif ch == "," and depth == 0:
            return s[:i], ",", s[i+1:]
    return s, "", ""

def _read_to_str():
    # capture read() output as string
    import io, contextlib
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        read()
    return buf.getvalue()

# --- workspace count --------------------------------------------------------
def set_workspace(n):
    n = max(1, min(10, int(n)))
    # The azerty table has fixed entries; "count" here would ideally comment/
    # uncomment entries. For safety in v1 we only report — full impl rewrites
    # the table. (Kept minimal per 'workability first'.)
    print(json.dumps({"ok": True, "count": n,
        "note": "workspace count write not yet implemented"}))

# --- category bind: add/update/remove hl.bind for quickshell:cat_N ----------
def set_category_bind(cat_index, mods_csv, key):
    """Add or update: hl.bind("<mods> + KEY", hl.dsp.global("quickshell:cat_N")).
    If key is empty, remove the bind line."""
    target = 'hl.dsp.global("quickshell:cat_%s")' % cat_index
    with open(BINDS_PATH, "r", encoding="utf-8") as f:
        lines = f.readlines()

    mods = [m for m in mods_csv.split(",") if m]
    has_super = "SUPER" in mods
    non_super = [m for m in mods if m != "SUPER"]

    # build the key expression
    if has_super:
        if non_super:
            keyexpr = 'mainMod .. " + %s + %s"' % (" + ".join(non_super), key)
        else:
            keyexpr = 'mainMod .. " + %s"' % key
    else:
        keyexpr = '"%s"' % (" + ".join(non_super + [key]) if non_super else key)

    new_line = 'hl.bind(%s, %s)\n' % (keyexpr, target)

    # find existing line for this category
    found = None
    for i, ln in enumerate(lines):
        if target in ln:
            found = i
            break

    if not key:  # remove
        if found is not None:
            del lines[found]
        result = {"ok": True, "removed": found is not None}
    elif found is not None:  # update
        lines[found] = new_line
        result = {"ok": True, "updated": True}
    else:  # append near the other quickshell binds, else end
        insert_at = len(lines)
        for i, ln in enumerate(lines):
            if 'quickshell:' in ln:
                insert_at = i + 1
        lines.insert(insert_at, new_line)
        result = {"ok": True, "added": True}

    with open(BINDS_PATH, "w", encoding="utf-8") as f:
        f.writelines(lines)
    print(json.dumps(result))

# --- main -------------------------------------------------------------------
def main():
    if len(sys.argv) < 2:
        print(json.dumps({"error": "no subcommand"})); return
    cmd = sys.argv[1]
    if cmd == "read":
        read()
    elif cmd == "setkey" and len(sys.argv) >= 5:
        setkey(sys.argv[2], sys.argv[3], sys.argv[4])
    elif cmd == "workspace" and len(sys.argv) >= 3:
        set_workspace(sys.argv[2])
    elif cmd == "setcat" and len(sys.argv) >= 5:
        set_category_bind(sys.argv[2], sys.argv[3], sys.argv[4])
    else:
        print(json.dumps({"error": "bad usage"}))

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(json.dumps({
            "groups": {"hyprland": [], "quickshell": [], "programs": [], "system": []},
            "workspace": {"count": 5},
            "error": str(e)
        }))
