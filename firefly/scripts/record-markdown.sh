#!/usr/bin/env bash

# append_row <file> <heading> <header> <row> — make sure <file> holds the
# section <heading> with a table headed <header>, creating the section or the
# header when absent, and append <row> after the section's last text line.
# Every other line is reproduced as it was.
append_row() (
  local file="$1" heading="$2" header="$3" row="$4"
  local dir sep tmp source
  dir="$(dirname "$file")"
  mkdir -p "$dir"
  # Lock the stable directory inode: the carrier itself is about to be replaced.
  command -v flock >/dev/null || refuse "flock is required to update the carrier"
  exec 9<"$dir"
  flock -x 9 || refuse "cannot lock carrier directory: $dir"
  if [[ -L "$file" || ( -e "$file" && ! -f "$file" ) ]]; then
    refuse "carrier is not a regular file: $file"
  fi
  source="$file"
  [[ -f "$file" ]] || source=/dev/null
  sep="$(printf '%s\n' "$header" | awk -F'|' '{ out = ""; for (i = 2; i < NF; i++) out = out "---|"; print "|" out }')"
  tmp="$(mktemp "$dir/.firefly-record.XXXXXX")" || refuse "cannot write in $dir"
  trap 'rm -f -- "$tmp"' EXIT
  # The row travels by environment: `awk -v` would eat the backslashes that
  # escape pipes.
  if ! ROW_HEADING="$heading" ROW_HEADER="$header" ROW_SEP="$sep" ROW_ROW="$row" \
    awk '
      function out(line) { print line; last = line }
      # Blank lines inside a section are held back: dropped when the row ends
      # the section (they would only stack up above it), kept when text
      # follows the table.
      function blanks(   n) { n = pending; pending = 0; while (n-- > 0) out("") }
      function close_section() {
        if (done) return
        if (need_header) { out(""); out(header); out(sep) }
        out(row)
        out("")
        done = 1
        pending = 0
      }
      BEGIN {
        heading = ENVIRON["ROW_HEADING"]; header = ENVIRON["ROW_HEADER"]
        sep = ENVIRON["ROW_SEP"]; row = ENVIRON["ROW_ROW"]
      }
      {
        if (!in_section && $0 == heading) {
          in_section = 1; need_header = 1; in_table = 0
          out($0)
          next
        }
        if (in_section && $0 ~ /^## /) {
          if (done) blanks(); else close_section()
          in_section = 0
          out($0)
          next
        }
        if (in_section) {
          if ($0 == "") { pending++; next }
          if (need_header) {
            # Text that is not our header stays where it is; a missing table
            # is created at the end of the section, after that text.
            if ($0 == header) { need_header = 0; in_table = 1 }
            blanks()
            out($0)
            next
          }
          if (in_table) {
            if ($0 ~ /^\|/) { blanks(); out($0); next }
            # The first text line after the table (a hand-written note below
            # it): the row goes right after the table, the note stays below.
            out(row)
            done = 1
            if (pending == 0) pending = 1
          }
          blanks()
          out($0)
          next
        }
        out($0)
      }
      END {
        if (in_section && !done) close_section()
        if (in_section) blanks()
        if (done) exit
        if (last != "") out("")
        out(heading)
        out("")
        out(header)
        out(sep)
        out(row)
        out("")
      }
    ' "$source" > "$tmp"; then
    rm -f "$tmp"
    refuse "cannot update $file"
  fi
  mv -f "$tmp" "$file"
)
