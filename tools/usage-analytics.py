#!/usr/bin/env python3
"""
openstate Usage Analytics — extract launch-ready metrics from state.jsonl
Run: python3 usage-analytics.py /path/to/repo/.openstate/state.jsonl
Or:  python3 usage-analytics.py --all /home/michael/repos/*/.openstate/state.jsonl
"""
import sys, json, duckdb, glob, os
from pathlib import Path
from datetime import datetime

def analyze_one(path: str, repo_name: str) -> dict:
    con = duckdb.connect()
    # Load with explicit schema handling
    con.execute(f"""
        CREATE TABLE facts AS 
        SELECT 
            fact.tag as tag,
            fact.proposition as proposition,
            fact.timestamp as timestamp,
            fact.source_event as source_event,
            fact.context as context,
            live,
            justifications
        FROM read_json_auto('{path}')
    """)
    
    # 1. Fact counts by tag
    tags = con.execute("""
        SELECT tag, count(*) as n
        FROM facts WHERE tag IS NOT NULL
        GROUP BY 1 ORDER BY 2 DESC
    """).fetchall()
    
    # 2. Live vs closed
    live = con.execute("""
        SELECT live::boolean as live, count(*) as n
        FROM facts GROUP BY 1
    """).fetchall()
    
    # 3. Tool usage
    tools = con.execute("""
        SELECT proposition, count(*) as n
        FROM facts 
        WHERE proposition LIKE 'tool.execute%'
        GROUP BY 1 ORDER BY 2 DESC LIMIT 20
    """).fetchall()
    
    # 4. Commands run
    cmds = con.execute("""
        SELECT proposition, count(*) as n
        FROM facts 
        WHERE proposition LIKE '%succeeded%' OR proposition LIKE '%failed%'
        GROUP BY 1 ORDER BY 2 DESC LIMIT 20
    """).fetchall()
    
    # 5. Sessions represented
    sessions = con.execute("""
        SELECT count(DISTINCT context.source_session) as n
        FROM facts WHERE context.source_session IS NOT NULL
    """).fetchone()
    
    # 6. Time span
    dates = con.execute("""
        SELECT min(timestamp) as first, max(timestamp) as last
        FROM facts WHERE timestamp IS NOT NULL
    """).fetchone()
    
    # 7. Resume capsules generated
    capsules = con.execute("""
        SELECT count(*) as n FROM facts 
        WHERE proposition LIKE '%capsule%' OR tag = 'capsule'
    """).fetchone()
    
    # 8. Assessments run
    assesses = con.execute("""
        SELECT count(*) as n FROM facts 
        WHERE proposition LIKE '%assess%'
    """).fetchone()
    
    # 9. Top blockers
    blockers = con.execute("""
        SELECT proposition, count(*) as n
        FROM facts WHERE tag = 'blocker' AND live = true
        GROUP BY 1 ORDER BY 2 DESC LIMIT 10
    """).fetchall()
    
    # 10. Failed attempts
    failed = con.execute("""
        SELECT proposition, count(*) as n
        FROM facts WHERE tag = 'failed_attempt'
        GROUP BY 1 ORDER BY 2 DESC LIMIT 10
    """).fetchall()
    
    # 11. Objectives
    objectives = con.execute("""
        SELECT proposition, count(*) as n
        FROM facts WHERE tag = 'objective'
        GROUP BY 1 ORDER BY 2 DESC LIMIT 5
    """).fetchall()
    
    # 12. Decisions
    decisions = con.execute("""
        SELECT proposition, count(*) as n
        FROM facts WHERE tag = 'decision'
        GROUP BY 1 ORDER BY 2 DESC LIMIT 5
    """).fetchall()
    
    # 13. In progress
    inprog = con.execute("""
        SELECT proposition, count(*) as n
        FROM facts WHERE tag = 'in_progress'
        GROUP BY 1 ORDER BY 2 DESC LIMIT 10
    """).fetchall()
    
    con.close()
    return {
        "repo": repo_name,
        "tags": tags,
        "live_closed": live,
        "tools": tools,
        "commands": cmds,
        "sessions": sessions[0] if sessions else 0,
        "first": dates[0] if dates else None,
        "last": dates[1] if dates else None,
        "capsules": capsules[0] if capsules else 0,
        "assesses": assesses[0] if assesses else 0,
        "blockers": blockers,
        "failed": failed,
        "objectives": objectives,
        "decisions": decisions,
        "inprog": inprog,
    }

def print_report(data: dict):
    d = data
    print(f"\n{'='*60}")
    print(f"REPO: {d['repo']}")
    print(f"{'='*60}")
    print(f"Sessions tracked: {d['sessions']}")
    print(f"Time span: {d['first']} → {d['last']}")
    print(f"Capsules generated: {d['capsules']}")
    print(f"Assessments run: {d['assesses']}")
    
    print(f"\n--- Fact tags ---")
    for tag, n in d['tags'][:15]:
        print(f"  {tag}: {n}")
    
    print(f"\n--- Live/Closed ---")
    for status, n in d['live_closed']:
        print(f"  {'LIVE' if status else 'CLOSED'}: {n}")
    
    print(f"\n--- Objectives ---")
    for prop, n in d['objectives']:
        print(f"  {prop[:100]}: {n}")
    
    print(f"\n--- Decisions ---")
    for prop, n in d['decisions']:
        print(f"  {prop[:100]}: {n}")
    
    print(f"\n--- In Progress ---")
    for prop, n in d['inprog'][:10]:
        print(f"  {prop[:100]}: {n}")
    
    print(f"\n--- Failed Attempts ---")
    for prop, n in d['failed'][:10]:
        print(f"  {prop[:100]}: {n}")
    
    print(f"\n--- Active Blockers ---")
    for b, n in d['blockers']:
        print(f"  {b[:100]}: {n}")
    
    print(f"\n--- Top Tools ---")
    for prop, n in d['tools'][:10]:
        print(f"  {prop[:80]}: {n}")
    
    print(f"\n--- Top Commands ---")
    for cmd, n in d['commands'][:10]:
        print(f"  {cmd[:80]}: {n}")

if __name__ == "__main__":
    import argparse
    p = argparse.ArgumentParser()
    p.add_argument("paths", nargs="*", help="state.jsonl files")
    p.add_argument("--all", action="store_true", help="scan all repos under ~/repos")
    args = p.parse_args()
    
    paths = []
    if args.all:
        for p in glob.glob(os.path.expanduser("~/repos/*/.openstate/state.jsonl")):
            if os.path.exists(p):
                paths.append(p)
    else:
        paths = args.paths
    
    if not paths:
        # default: current repo
        default = Path(__file__).parent.parent / ".openstate" / "state.jsonl"
        if default.exists():
            paths = [str(default)]
    
    all_data = []
    for p in paths:
        repo = Path(p).parent.parent.name
        try:
            data = analyze_one(p, repo)
            all_data.append(data)
            print_report(data)
        except Exception as e:
            print(f"Failed {repo}: {e}")
    
    # Cross-repo summary
    if len(all_data) > 1:
        print(f"\n{'='*60}")
        print("CROSS-REPO SUMMARY")
        print(f"{'='*60}")
        total_sessions = sum(d['sessions'] for d in all_data)
        total_capsules = sum(d['capsules'] for d in all_data)
        total_assesses = sum(d['assesses'] for d in all_data)
        print(f"Total repos: {len(all_data)}")
        print(f"Total sessions: {total_sessions}")
        print(f"Total capsules: {total_capsules}")
        print(f"Total assessments: {total_assesses}")
        # Aggregate tags
        tag_totals = {}
        for d in all_data:
            for tag, n in d['tags']:
                tag_totals[tag] = tag_totals.get(tag, 0) + n
        print(f"\nAggregated tags:")
        for tag, n in sorted(tag_totals.items(), key=lambda x: -x[1])[:15]:
            print(f"  {tag}: {n}")
