#!/bin/bash
# Opens generated PDF files after typst compile commands

RESULT=$(python3 -c "
import json, sys, os, re

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

if data.get('tool_name') != 'Bash':
    sys.exit(0)

command = data.get('tool_input', {}).get('command', '')
if 'typst compile' not in command:
    sys.exit(0)

# Extract working directory from cd command
workdir = ''
m = re.search(r'cd\s+\"([^\"]+)\"', command)
if m:
    workdir = m.group(1)

# Find all .pdf paths in the command
pdfs = re.findall(r'[^\s]+\.pdf', command)

# If no explicit PDF, derive from .typ input
if not pdfs:
    typs = re.findall(r'[^\s]+\.typ', command)
    pdfs = [t.replace('.typ', '.pdf') for t in typs]

for pdf in pdfs:
    if not os.path.isabs(pdf) and workdir:
        pdf = os.path.join(workdir, pdf)
    if os.path.isfile(pdf):
        print(pdf)
" 2>/dev/null)

if [ -n "$RESULT" ]; then
    echo "$RESULT" | while read -r pdf; do
        open "$pdf"
    done
fi