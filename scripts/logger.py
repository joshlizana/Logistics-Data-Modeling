"""
Shared build logger — appends timestamped run output to project_log.md.

Usage:
    from logger import BuildLogger
    log = BuildLogger("Build")
    log("message")
    log.flush()   # writes to project_log.md
"""

import datetime
from pathlib import Path

LOG_PATH = 'project_log.md'


class BuildLogger:
    def __init__(self, run_label: str):
        self.run_label = run_label
        self.start_time = datetime.datetime.now()
        self._lines = []

    def __call__(self, msg: str = ''):
        print(msg)
        self._lines.append(str(msg))

    def flush(self):
        elapsed = (datetime.datetime.now() - self.start_time).total_seconds()
        run_time = self.start_time.strftime('%Y-%m-%d %H:%M')
        with open(LOG_PATH, 'a') as f:
            f.write(f"\n---\n\n## {self.run_label}: {run_time} ({elapsed:.1f}s)\n\n")
            f.write('\n'.join(self._lines) + '\n')
