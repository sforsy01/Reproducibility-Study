import argparse
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parent

parser = argparse.ArgumentParser()
parser.add_argument("--counts-dir", type=Path, default=ROOT / "output_counts")
parser.add_argument("--out-file", type=Path, default=ROOT / "combined_counts.csv")
args = parser.parse_args()

files = sorted(args.counts_dir.glob("*_counts.txt"))
if not files:
    raise SystemExit(f"No *_counts.txt files found in {args.counts_dir}")

dfs = []
for f in files:
    sample = f.name.replace("_counts.txt", "")
    df = pd.read_csv(f, sep="\t", header=None, names=["Gene", sample])
    # Drop htseq-count summary rows (__no_feature, __ambiguous, etc.)
    df = df[~df["Gene"].str.startswith("__")]
    dfs.append(df.set_index("Gene"))

# Join all samples on Gene (outer join), genes missing in a sample become 0
combined_df = pd.concat(dfs, axis=1, join="outer").fillna(0).astype(int)

# Gene first, then samples in alphabetical order
combined_df = combined_df[sorted(combined_df.columns)].reset_index()

args.out_file.parent.mkdir(parents=True, exist_ok=True)
combined_df.to_csv(args.out_file, index=False)

print(f"Wrote {args.out_file}")