"""Bundle modular Lua into a stock TI-Nspire script; optional desktop Luna packaging."""
from pathlib import Path
import argparse
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def bundle(entry=True):
    parts = ["-- Mote: Memory Garden | stock TI-Nspire CX CAS | API 2.0",
             'platform.apiLevel = "2.0"' if entry else "",
             "local factories, loaded = {}, {}",
             "local function require(name)",
             "  if loaded[name] then return loaded[name] end",
             "  assert(factories[name], 'Unknown module: '..name)",
             "  loaded[name] = factories[name]()",
             "  return loaded[name]", "end"]
    for path in sorted((ROOT / "src").rglob("*.lua")):
        if path.name == "main.lua":
            continue
        name = ".".join(path.relative_to(ROOT / "src").with_suffix("").parts)
        parts.extend([f'factories["{name}"] = function()', path.read_text("utf-8"), "end"])
    parts.append((ROOT / "src/main.lua").read_text("utf-8") if entry else "return require")
    return "\n".join(parts) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--luna", type=Path)
    args = parser.parse_args()
    out = ROOT / "build"
    out.mkdir(exist_ok=True)
    script = out / "mote.lua"
    script.write_text(bundle(), encoding="utf-8", newline="\n")
    print(f"Built build/{script.name} ({script.stat().st_size} bytes)")
    if args.luna:
        subprocess.run([str(args.luna.resolve()), str(script), str(out / "mote.tns")],
                       check=True)
        print("Packaged build/mote.tns; TI device open still requires verification")


if __name__ == "__main__":
    main()
