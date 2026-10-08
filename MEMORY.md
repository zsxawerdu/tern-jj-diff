# mem v2
# audience: models only. not docs. not changelog. loaded every session, so keep it small.
# load: after AGENTS.md, before non-trivial work.
# keep: traps, gotchas, schema, environment quirks, "don't do X" + why. one fact per entry.
# never: what code or docs already say, feature descriptions, test counts, status, todos.
# user rules ("never edit X") go in AGENTS.md, not here.
# write: upsert by id. never clobber other ids.
# delete: wrong, stale or promoted → remove the entry outright. vcs keeps history.
# tombstone: only to stop a false fact being re-learned: `k: !drop <why>`. remove after 30 days.
# conflict: AGENTS.md > this. this > unaided recall.
# budget: ≤40 entries, ~10 KB. k ≤300 chars. over budget → promote or delete before adding.
# when: date last verified. relying on one >30 days old → re-check; holds → bump, fails → delete.
# shape, exactly (blank line between entries):
#
# id: kebab-slug
# k: the fact, one line
# src: path/or/api
# when: 2026-09-24
