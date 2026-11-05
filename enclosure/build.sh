#!/usr/bin/env bash
# Render all STLs and PNG previews. Needs openscad (2021.01+); PNGs need a display
# (on a headless Linux box this script uses xvfb-run automatically).
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p stl png
X=(); command -v xvfb-run >/dev/null && [ -z "${DISPLAY:-}" ] && X=(xvfb-run -a -s "-screen 0 1600x1200x24")
png() { "${X[@]}" openscad --imgsize=1400,1000 --autocenter --viewall --colorscheme=Tomorrow "$@"; }

for spec in "controller_case_4x:case4x:base lid" "controller_case_6x:case6x:base lid" "dm542t_rack:rack:base cover"; do
  IFS=: read -r src name parts <<<"$spec"
  for p in $parts; do
    echo "== $name $p"
    openscad -o "stl/${name}_${p}.stl" -D "part=\"$p\"" "$src.scad"
    # PNG of the printed part straight from the STL (fast, no second CGAL pass)
    tmp=$(mktemp --suffix=.scad); echo "color(\"Orange\") import(\"$PWD/stl/${name}_${p}.stl\");" > "$tmp"
    png --render -o "png/${name}_${p}.png" --camera=0,0,0,55,0,25,500 "$tmp"; rm -f "$tmp"
  done
  echo "== $name assembly"
  png -o "png/${name}_assembly.png" --camera=0,0,0,55,0,25,500 -D 'part="assembly"' "$src.scad"
  png -o "png/${name}_assembly_back.png" --camera=0,0,0,55,0,205,500 -D 'part="assembly"' "$src.scad"
done
echo done
