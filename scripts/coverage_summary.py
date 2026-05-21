#!/usr/bin/env python3
"""Print coverage summary for lib/core/constants/ from lcov.info"""

import sys

def main():
    path = sys.argv[1] if len(sys.argv) > 1 else 'coverage/lcov.info'
    with open(path) as f:
        content = f.read()

    records = content.split('SF:')
    total = 0
    covered = 0
    print()
    uncovered_by_file = {}
    for record in records[1:]:
        if 'lib/core/constants/' not in record:
            continue
        lines = record.strip().split('\n')
        sf = lines[0]
        sf_total = 0
        sf_covered = 0
        uncovered_lines = []
        for l in lines[1:]:
            if l.startswith('DA:'):
                parts = l[3:].split(',')
                lineno = int(parts[0])
                hits = int(parts[1])
                sf_total += 1
                if hits > 0:
                    sf_covered += 1
                else:
                    uncovered_lines.append(lineno)
        fname = sf.split('/')[-1]
        pct = sf_covered / sf_total * 100 if sf_total > 0 else 0
        print(f'  {fname:30s} {sf_covered}/{sf_total} ({pct:.1f}%)')
        total += sf_total
        covered += sf_covered
        if uncovered_lines:
            with open(sf) as src_file:
                src = src_file.readlines()
            details = []
            for u in uncovered_lines:
                content_line = src[u-1].rstrip() if u <= len(src) else '???'
                details.append(f'L{u}: {content_line}')
            uncovered_by_file[fname] = details

    if total > 0:
        pct = covered / total * 100
        print(f'  {"TOTAL":30s} {covered}/{total} ({pct:.1f}%)')
    print()

    if uncovered_by_file:
        print('Remaining uncovered lines (excluding private constructors):')
        for fname, details in uncovered_by_file.items():
            for d in details:
                if 'const' in d and '._();' in d:
                    continue
                print(f'  {fname}: {d}')
        print()

if __name__ == '__main__':
    main()
