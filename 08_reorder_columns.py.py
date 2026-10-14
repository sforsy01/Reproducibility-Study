import argparse
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parent

parser = argparse.ArgumentParser()
parser.add_argument("--in-file", type=Path, default=ROOT / "combined_counts.csv")
parser.add_argument("--out-file", type=Path, default=ROOT / "reordered_combined_counts.csv")
args = parser.parse_args()

df = pd.read_csv(args.in_file)

ordered_columns = [
    "Gene",
    "S1-02-T1", "S1-02-T2", "S1-02-T3", "S1-03-T1", "S1-03-T2", "S1-03-T3",
    "S1-04-T1", "S1-04-T2", "S1-04-T3", "S1-05-T1", "S1-05-T2", "S1-05-T3",
    "S1-07-T1", "S1-07-T2", "S1-07-T3", "S1-09-T1", "S1-09-T2", "S1-09-T3",
    "S1-10-T1", "S1-10-T2", "S1-10-T3", "S1-11-T1", "S1-11-T2", "S1-11-T3",
    "S1-12-T1", "S1-12-T2", "S1-12-T3",
    "S2-03", "S2-04", "S2-06", "S2-07", "S2-08", "S2-09", "S2-11",
]

# Report mismatches instead of silently dropping columns
missing = [c for c in ordered_columns if c not in df.columns]
extra = [c for c in df.columns if c not in ordered_columns]
if missing:
    print(f"WARNING: in the list but not in the file: {missing}")
if extra:
    print(f"WARNING: in the file but not in the list (will be dropped): {extra}")

df = df[[c for c in ordered_columns if c in df.columns]]

args.out_file.parent.mkdir(parents=True, exist_ok=True)
df.to_csv(args.out_file, index=False)
print(f"Wrote {args.out_file} with {df.shape[1] - 1} samples")