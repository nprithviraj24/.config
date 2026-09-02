#!/usr/bin/env bash
# duet-round.sh — run one Codex turn of a duet.
#
# Usage: duet-round.sh <round-number> <prompt-file> <out-file>
#   env: DUET_ROOT (default $PWD) — the directory holding .duet/
#
# Pins three things across rounds and refuses to continue when any has drifted:
#   .thread  the Codex thread id      (wrong thread = wrong argument)
#   .cwd     the Codex working root   (wrong root  = right thread, wrong repo)
#   .inputs  a fingerprint of the repo+brief the argument is about
#
# Exit codes:
#   0 ok            3 pinned thread is gone (caller may re-seed)
#   1 usage/setup   4 thread mismatch (abort, never retry)
#   5 no usable final message   6 codex failed for some other reason
#   7 another round is already running in this root
set -uo pipefail

die() { echo "duet: $*" >&2; exit 1; }
[ $# -eq 3 ] || die "usage: duet-round.sh <round> <prompt-file> <out-file>"

ROUND=$1
PROMPT_FILE=$(realpath "$2") || die "prompt file not found: $2"
[ -s "$PROMPT_FILE" ] || die "prompt file is empty: $PROMPT_FILE"
OUT=$(realpath -m "$3")
ROOT=$(realpath "${DUET_ROOT:-$PWD}") || die "root not found: ${DUET_ROOT:-$PWD}"

DUET_DIR="$ROOT/.duet"
THREAD_FILE="$DUET_DIR/.thread"
CWD_FILE="$DUET_DIR/.cwd"
INPUTS_FILE="$DUET_DIR/.inputs"
EVENTS="$DUET_DIR/rounds/$(printf '%03d' "$ROUND")-codex.jsonl"
ERRLOG="$EVENTS.err"
mkdir -p "$DUET_DIR/rounds"

# One round at a time per root: .thread/.cwd/the event log are all shared mutable
# state, and two concurrent rounds will interleave writes and read each other's logs.
exec 9>"$DUET_DIR/.lock"
flock -n 9 || { echo "duet: another round is already running in $ROOT" >&2; exit 7; }

thread_id_of() {
  head -1 "$1" 2>/dev/null | grep -oE '"thread_id":"[^"]+"' | cut -d'"' -f4 || true
}

# What the argument is *about*. If the repo or the brief moves between rounds, the two
# sides are arguing about different inputs while every identity check still passes.
input_fingerprint() {
  { git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo "no-git"
    git -C "$ROOT" status --porcelain 2>/dev/null
    cat "$DUET_DIR/BRIEF.md" 2>/dev/null
  } | sha256sum | cut -d' ' -f1
}

check_input_drift() {
  local now prev
  now=$(input_fingerprint)
  prev=$(cat "$INPUTS_FILE" 2>/dev/null || true)
  if [ -n "$prev" ] && [ "$prev" != "$now" ]; then
    echo "duet: WARNING — repo or brief changed since the last round." >&2
    echo "duet: Codex is reasoning from an earlier version but reads the current files." >&2
    echo "duet: Disagreement may be an artefact. Say so when reporting this round." >&2
  fi
  printf '%s\n' "$now" > "$INPUTS_FILE"
}

# `codex -o` writes nothing when a run ends on a tool call. The reasoning survives in
# the event log, but the last agent_message may be a mid-turn status line rather than an
# answer — so only treat it as final if no tool call followed it.
ensure_output() {
  [ -s "$OUT" ] && return 0
  echo "duet: codex wrote no final message; recovering from the event log" >&2
  python3 - "$EVENTS" "$OUT" <<'PY' || true
import json, sys
events, out = sys.argv[1], sys.argv[2]
last_msg, trailing_tool = None, False
try:
    for line in open(events):
        try: e = json.loads(line)
        except Exception: continue
        if e.get("type") != "item.completed": continue
        item = e.get("item") or {}
        if item.get("type") == "agent_message" and (item.get("text") or "").strip():
            last_msg, trailing_tool = item["text"], False
        elif last_msg is not None:
            trailing_tool = True          # a tool ran after the last message
except FileNotFoundError:
    sys.exit(0)
if last_msg:
    banner = ("> PARTIAL: recovered from the event log. Codex ran a tool after this and\n"
              "> never produced a final answer. Treat as an interim note, NOT a position.\n\n"
              if trailing_tool else
              "> Recovered from the event log; Codex ended without writing a final message.\n\n")
    open(out, "w").write(banner + last_msg)
PY
  [ -s "$OUT" ] || { echo "duet: no recoverable output in $EVENTS" >&2; exit 5; }
  grep -q '^> PARTIAL' "$OUT" && echo "duet: output is PARTIAL — do not score this round" >&2
  return 0
}

run_codex() {   # never let a stale file from a previous attempt read as this round's answer
  rm -f "$OUT"
  "$@" < "$PROMPT_FILE" > "$EVENTS" 2>"$ERRLOG"
}

spawn() {
  check_input_drift
  local rc tid
  run_codex codex exec --json -s read-only -C "$ROOT" --skip-git-repo-check -o "$OUT"  -
  rc=$?
  tid=$(thread_id_of "$EVENTS")
  if [ -z "$tid" ]; then
    echo "duet: no thread_id in codex output (status $rc)" >&2
    sed -n '1,3p' "$ERRLOG" >&2 2>/dev/null || true
    exit 6
  fi
  # Pin cwd BEFORE the thread id: a crash between the two must not leave a thread
  # with no recorded root, which is the state that silently resumes in the wrong repo.
  printf '%s\n' "$ROOT" > "$CWD_FILE"
  printf '%s\n' "$tid"  > "$THREAD_FILE"
  if [ $rc -ne 0 ]; then
    echo "duet: codex exited $rc; thread $tid pinned, output may be incomplete" >&2
    sed -n '1,3p' "$ERRLOG" >&2 2>/dev/null || true
  fi
  ensure_output
  echo "duet: spawned $tid in $ROOT"
}

resume() {
  local pinned pinned_cwd got rc
  pinned=$(cat "$THREAD_FILE")
  [ -s "$CWD_FILE" ] || die "thread $pinned is pinned but .cwd is missing; refusing to guess the working root (delete .duet/.thread to re-seed)"
  pinned_cwd=$(cat "$CWD_FILE")
  [ -d "$pinned_cwd" ] || die "pinned cwd $pinned_cwd no longer exists"
  [ "$pinned_cwd" = "$ROOT" ] || die "pinned cwd $pinned_cwd does not match root $ROOT; this .duet was moved or copied"

  check_input_drift

  # `codex exec resume` takes neither -s nor -C: sandbox goes through -c, and the
  # working root is inherited from this shell. All state paths above are absolute,
  # so the cd is safe.
  cd "$pinned_cwd" || die "cannot enter pinned cwd $pinned_cwd"

  run_codex codex exec resume "$pinned" --json --skip-git-repo-check \
    -c sandbox_mode=read-only -o "$OUT" -
  rc=$?

  if [ $rc -ne 0 ]; then
    # Only "no rollout found" actually means the thread is gone. Auth failures, rate
    # limits and crashes must NOT cause the caller to discard a still-valid thread.
    if grep -qi 'no rollout found' "$ERRLOG" 2>/dev/null; then
      echo "duet: thread $pinned no longer exists" >&2
      exit 3
    fi
    echo "duet: codex failed (status $rc) — thread $pinned is probably still valid" >&2
    sed -n '1,3p' "$ERRLOG" >&2 2>/dev/null || true
    exit 6
  fi

  got=$(thread_id_of "$EVENTS")
  [ "$got" = "$pinned" ] || { echo "duet: THREAD MISMATCH pinned=$pinned got=${got:-<none>}" >&2; exit 4; }
  ensure_output
  echo "duet: resumed $pinned in $pinned_cwd"
}

if [ -s "$THREAD_FILE" ]; then resume; else spawn; fi
