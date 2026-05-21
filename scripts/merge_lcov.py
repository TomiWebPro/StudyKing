#!/usr/bin/env python3
"""Merge multiple lcov.info files. Usage: python3 merge_lcov.py output.info input1.info [input2.info ...]"""

import sys
from collections import defaultdict

def parse_lcov(path):
    records = defaultdict(lambda: {'lines': {}})
    with open(path) as f:
        content = f.read()
    for record in content.split('SF:'):
        if not record.strip():
            continue
        lines = record.strip().split('\n')
        sf = lines[0].strip()
        if not sf:
            continue
        da_lines = {}
        for l in lines[1:]:
            if l.startswith('DA:'):
                parts = l[3:].split(',')
                lineno = int(parts[0])
                hits = int(parts[1])
                da_lines[lineno] = da_lines.get(lineno, 0) + hits
        if da_lines:
            records[sf]['lines'].update(da_lines)
    return records

def write_lcov(records, path):
    with open(path, 'w') as f:
        for sf, data in sorted(records.items()):
            f.write(f'SF:{sf}\n')
            for lineno in sorted(data['lines']):
                f.write(f'DA:{lineno},{data["lines"][lineno]}\n')
            f.write('end_of_record\n')

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print('Usage: merge_lcov.py output.info input1.info [input2.info ...]')
        sys.exit(1)
    output = sys.argv[1]
    inputs = sys.argv[2:]
    merged = defaultdict(lambda: {'lines': {}})
    for inp in inputs:
        records = parse_lcov(inp)
        for sf, data in records.items():
            for lineno, hits in data['lines'].items():
                merged[sf]['lines'][lineno] = merged[sf]['lines'].get(lineno, 0) + hits
    write_lcov(merged, output)
    print(f'Merged {len(inputs)} coverage files into {output}')
    total_lines = sum(len(d['lines']) for d in merged.values())
    covered_lines = sum(1 for d in merged.values() for h in d['lines'].values() if h > 0)
    print(f'Total lines: {total_lines}, Covered: {covered_lines} ({covered_lines/total_lines*100:.1f}%)')
