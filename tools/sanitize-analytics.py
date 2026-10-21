#!/usr/bin/env python3
"""
Sanitize analytics for public release - pure Python, no DuckDB
"""
import sys, json, glob, os, re, statistics
from pathlib import Path
from collections import Counter, defaultdict
from datetime import datetime, timezone

PROJECT_MAP = {
    'airframe-workspace': 'project-alpha',
    'pounce-p2p': 'project-beta', 
    'mikedb': 'project-gamma',
    'dzero-cas': 'project-delta',
    'openstate': 'project-epsilon',
    'chat-chronicle': 'project-zeta',
    'adama': 'project-eta',
    'auxide-workspace': 'project-theta',
    'openstate-private': 'project-iota',
}

PATH_PATTERNS = [
    (r"/home/michael/repos/[^\s\"';\/\\]+", '/repo'),
    (r"/mnt/c/Users/micha/repos/[^\s\"';\/\\]+", '/repo'),
    (r"/[cC]/Users/micha/repos/[^\s\"';\/\\]+", '/repo'),
    (r"[cC]:/Users/micha/repos/[^\s\"';\/\\]+", '/repo'),
    (r"[cC]:\\Users\\micha\\repos\\[^\s\"';\/\\]+", '/repo'),
    # Host-encoded project directories (Claude Code: -home-<user>-repos-<repo>).
    (r"-home-michael-repos-[^\s\"';\/\\]+", '-repo'),
    (r"-mnt-c-Users-micha-repos-[^\s\"';\/\\]+", '-repo'),
    (r"-home-michael\b", '-home'),
    (r"/tmp/opencode/[^\s\"';\/\\]+", '/tmp/work'),
    (r'/home/michael/\.config/opencode', '~/.config/opencode'),
    (r'/mnt/c/Users/micha/\.config/opencode', '~/.config/opencode'),
    (r'/home/michael/?', '~/'),
    (r'/mnt/c/Users/micha/?', '~/'),
    (r'/[cC]/Users/micha/?', '~/'),
    (r'[cC]:/Users/micha/?', '~/'),
    (r'[cC]:\\Users\\micha\\?', '~/'),
    # Second local username (Linux dev box). AFTER the /home/michael rules:
    # '/home/micha' is a prefix of '/home/michael' and must not match first.
    (r"/home/micha/repos/[^\s\"';\/\\]+", '/repo'),
    (r"/home/micha/?", '~/'),
    # Tokenized paths (separator-stripped by upstream recurring-failure
    # keying): 'mnt c users micha ...', 'c: users micha ...'.
    (r"\bmnt c users micha repos [^\s\"';\/\\]+", '/repo'),
    (r"\b[cC]: users micha repos [^\s\"';\/\\]+", '/repo'),
    (r"\bmnt c users micha\b", '~'),
    (r"\b[cC]: users micha\b", '~'),
]

def sanitize_proposition(prop: str) -> str:
    if not prop:
        return prop
    for pattern, repl in PATH_PATTERNS:
        prop = re.sub(pattern, repl, prop)
    for real, fake in PROJECT_MAP.items():
        prop = prop.replace(real, fake)
    return prop

def resolve_repo_name(repo: str) -> str:
    """Fail-closed PROJECT_MAP lookup: an unmapped repo stops the run with
    exit 2 instead of leaking the raw name into public artifacts."""
    if repo not in PROJECT_MAP:
        print(
            f"sanitize-analytics: unmapped repo '{repo}' — add it to PROJECT_MAP, then re-run",
            file=sys.stderr,
        )
        raise SystemExit(2)
    return PROJECT_MAP[repo]

def sanitize_repo_name(name: str) -> str:
    return resolve_repo_name(name)

# Engine fact names whose legacy analytics tag differs from the snake-cased name.
SNAPSHOT_TAGS = {"FailedAttempt": "failed_attempt", "Blocked": "blocker", "HotFile": "file_activity"}

def snake(name: str) -> str:
    return re.sub(r"(?<!^)(?=[A-Z])", "_", name).lower()

def state_records(f):
    """Yield state as legacy {fact: {tag, proposition, timestamp, context}, live} records.

    Reads both layouts: legacy JSONL (one record per line) and the engine's
    single-line snapshot {arena, facts, fact_ids, sessions, ...} (openstate-xfu8),
    where a fact names its text by arena index and fact_ids lists every fact
    ever recorded, retracted ones included.
    """
    text = f.read()
    try:
        snapshot = json.loads(text)
    except ValueError:
        snapshot = None
    if not (isinstance(snapshot, dict) and "arena" in snapshot and "facts" in snapshot):
        for line in text.splitlines():
            line = line.strip()
            if not line:
                continue
            try:
                yield json.loads(line)
            except ValueError:
                continue
        return
    arena = [entry.get("text", "") for entry in snapshot["arena"]]
    live = {json.dumps(fact, sort_keys=True) for fact in snapshot["facts"]}
    sessions = {fid: sid for fid, sid in snapshot.get("sessions", [])}
    recorded = snapshot.get("fact_ids") or list(enumerate(snapshot["facts"]))
    for fid, fact in recorded:
        (name, fields), = fact.items()
        node = next((fields[k] for k in ("proposition", "command", "path", "name", "file") if isinstance(fields.get(k), int)), None)
        prop = arena[node] if node is not None and 0 <= node < len(arena) else ""
        if name == "Completed":
            prop += " succeeded"
        elif name == "FailedAttempt":
            prop += " failed"
        ts = fields.get("ts")
        yield {
            "fact": {
                "tag": SNAPSHOT_TAGS.get(name, snake(name)),
                "proposition": prop,
                "timestamp": datetime.fromtimestamp(ts, timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ") if isinstance(ts, int) else None,
                "context": {"source_session": sessions.get(fid)} if fid in sessions else {},
            },
            "live": json.dumps(fact, sort_keys=True) in live,
        }

def analyze_file(path: str, repo_name: str, safe_name: str) -> dict:
    tags = Counter()
    live_closed = Counter()
    tools = Counter()
    cmds = Counter()
    sessions = set()
    timestamps = []
    capsules = 0
    assesses = 0
    blockers = Counter()
    failed = Counter()
    objectives = Counter()
    decisions = Counter()
    inprog = Counter()
    corrected = 0
    recurring = Counter()
    file_edits_per_session = Counter()
    cmds_per_session = Counter()
    
    with open(path) as f:
        for d in state_records(f):
            
            fact = d.get('fact', {})
            tag = fact.get('tag')
            prop = fact.get('proposition', '')
            ts = fact.get('timestamp')
            src = fact.get('source_event')
            ctx = fact.get('context', {})
            live = d.get('live', True)
            
            safe_prop = sanitize_proposition(prop)
            session = ctx.get('source_session')
            
            if tag:
                tags[tag] += 1
            live_closed[live] += 1
            
            if session:
                sessions.add(session)
            
            if ts:
                timestamps.append(ts)
            
            if prop:
                if prop.startswith('tool.'):
                    tools[safe_prop] += 1
                if 'succeeded' in prop or 'failed' in prop:
                    cmds[safe_prop] += 1
                if 'capsule' in prop.lower() or tag == 'capsule':
                    capsules += 1
                if 'assess' in prop.lower():
                    assesses += 1
                if tag == 'blocker' and live:
                    blockers[safe_prop] += 1
                if tag == 'failed_attempt':
                    failed[safe_prop] += 1
                if tag == 'objective':
                    objectives[safe_prop] += 1
                if tag == 'decision':
                    decisions[safe_prop] += 1
                if tag == 'in_progress':
                    inprog[safe_prop] += 1
                if tag == 'corrected':
                    corrected += 1
                if tag == 'recurring_failure':
                    recurring[safe_prop] += 1
                if tag == 'file_activity' and session:
                    file_edits_per_session[session] += 1
                if ('succeeded' in prop or 'failed' in prop) and session:
                    cmds_per_session[session] += 1
    
    return {
        "repo": safe_name,
        "tags": tags.most_common(),
        "live_closed": {str(k): v for k, v in live_closed.items()},
        "tools": tools.most_common(30),
        "commands": cmds.most_common(30),
        "sessions": len(sessions),
        "first": min(timestamps) if timestamps else None,
        "last": max(timestamps) if timestamps else None,
        "capsules": capsules,
        "assesses": assesses,
        "blockers": blockers.most_common(10),
        "failed": failed.most_common(10),
        "objectives": objectives.most_common(10),
        "decisions": decisions.most_common(10),
        "inprog": inprog.most_common(20),
        "corrected": corrected,
        "recurring": recurring.most_common(10),
        "file_edits_per_session": dict(file_edits_per_session),
        "cmds_per_session": dict(cmds_per_session),
    }

def analyze_all(output_dir: str):
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)
    
    all_data = []
    
    for p in glob.glob(os.path.expanduser("~/repos/*/.openstate/state.jsonl")):
        if not os.path.exists(p):
            continue
        repo = Path(p).parent.parent.name
        safe_name = resolve_repo_name(repo)
        
        try:
            data = analyze_file(p, repo, safe_name)
            all_data.append(data)
            
            with open(output_path / f"{safe_name}-analytics.json", "w") as f:
                json.dump(data, f, indent=2, default=str)
                
            print(f"  ✓ {repo} → {safe_name}")
        except Exception as e:
            print(f"  ✗ {repo}: {e}")
            continue
    
    # Cross-repo aggregate
    aggregate = aggregate_all(all_data)
    with open(output_path / "aggregate-analytics.json", "w") as f:
        json.dump(aggregate, f, indent=2, default=str)
    
    # Also save combined raw data for log drops
    with open(output_path / "all-repos-combined.json", "w") as f:
        json.dump(all_data, f, indent=2, default=str)
    
    print(f"\nSaved {len(all_data)} sanitized repo analytics to {output_dir}")
    return all_data

def aggregate_all(all_data):
    total_sessions = sum(d['sessions'] for d in all_data)
    total_capsules = sum(d['capsules'] for d in all_data)
    total_assesses = sum(d['assesses'] for d in all_data)
    total_corrected = sum(d['corrected'] for d in all_data)
    
    tag_totals = Counter()
    tool_totals = Counter()
    for d in all_data:
        for tag, n in d['tags']:
            tag_totals[tag] += n
        for tool, n in d['tools']:
            tool_totals[tool] += n
    
    all_file_edits = []
    all_cmds = []
    for d in all_data:
        all_file_edits.extend(d['file_edits_per_session'].values())
        all_cmds.extend(d['cmds_per_session'].values())
    
    return {
        "total_repos": len(all_data),
        "total_sessions": total_sessions,
        "total_capsules": total_capsules,
        "total_assesses": total_assesses,
        "total_corrected": total_corrected,
        "aggregated_tags": tag_totals.most_common(),
        "aggregated_tools": tool_totals.most_common(),
        "avg_edits_per_session": statistics.mean(all_file_edits) if all_file_edits else 0,
        "avg_cmds_per_session": statistics.mean(all_cmds) if all_cmds else 0,
        "median_edits_per_session": statistics.median(all_file_edits) if all_file_edits else 0,
        "median_cmds_per_session": statistics.median(all_cmds) if all_cmds else 0,
        "repo_count": len(all_data),
    }

if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "public-analytics"
    analyze_all(out)
