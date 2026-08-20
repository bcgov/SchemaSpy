#!/usr/bin/env bash
# Convert SQL Server schema exports into scripts that the Docker MSSQL
# initialization service can execute safely.
#
# Usage: convert-mssql-schema.sh SOURCE_DIRECTORY OUTPUT_DIRECTORY
#
# The source directory is expected to contain one or more .sql files, such as
# files exported by SQL Server Management Studio. Each file is normalized for
# line-oriented processing, split into GO-delimited batches, and filtered to
# retain schema-related statements. The converted files keep their original
# names and are written to a freshly recreated output directory.
#
# The converter intentionally removes database-level setup that belongs to the
# host environment (security, storage, settings, and data changes). It also
# adds the change-tracking statements needed by CHANGETABLE-based modules.
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 SOURCE_DIRECTORY OUTPUT_DIRECTORY" >&2
  exit 1
fi

source_directory=$1
output_directory=$2

# Fail before touching the output if the input path is invalid or unsafe.
if [[ ! -d "$source_directory" ]]; then
  echo "ERROR: MSSQL initialization source directory does not exist: $source_directory" >&2
  exit 1
fi

case "$output_directory" in
  ""|.|./|/)
    echo "ERROR: Refusing to write to unsafe output directory: $output_directory" >&2
    exit 1
    ;;
esac

if [[ "$(cd "$source_directory" && pwd -P)" == "$(cd "$(dirname "$output_directory")" && pwd -P)/$(basename "$output_directory")" ]]; then
  echo "ERROR: Source and output directories must be different." >&2
  exit 1
fi

rm -rf "$output_directory"
mkdir -p "$output_directory"

# Process every SQL file case-insensitively, while preserving each filename.
shopt -s nullglob nocaseglob
source_scripts=("$source_directory"/*.sql)

if [[ ${#source_scripts[@]} -eq 0 ]]; then
  echo "ERROR: No .sql scripts found in: $source_directory" >&2
  exit 1
fi

for source_script in "${source_scripts[@]}"; do
  output_script="$output_directory/$(basename "$source_script")"
  byte_order_mark="$(od -An -tx1 -N3 "$source_script" | tr -d ' \n')"

  # Normalize the encodings commonly emitted by SSMS before awk sees the SQL.
  # UTF-16LE needs its BOM and NUL bytes removed; UTF-8 only needs its BOM
  # removed. Other files are passed through unchanged.
  case "$byte_order_mark" in
    fffe*) tail -c +3 "$source_script" | tr -d '\000' ;;
    efbbbf*) tail -c +4 "$source_script" ;;
    *) cat "$source_script" ;;
  esac | LC_ALL=C awk '
    # Handle one GO-delimited batch. Batches that are not useful for schema
    # documentation are discarded; retained batches are emitted with GO so
    # the MSSQL initialization runner executes them independently.
    function emit_batch() {
      if (batch == "") {
        return
      }

      normalized = toupper(batch)
      if (normalized ~ /CREATE[[:space:]]+DATABASE[[:space:]]+/) {
        if (match(batch, /CREATE[[:space:]]+DATABASE[[:space:]]+(\[[^]]+\]|[A-Za-z0-9_]+)/)) {
          print substr(batch, RSTART, RLENGTH)
          print "GO"
        }
      } else if (normalized ~ /(CREATE[[:space:]]+(USER|LOGIN|ROLE)|ALTER[[:space:]]+ROLE|ALTER[[:space:]]+AUTHORIZATION|ALTER[[:space:]]+DATABASE|ALTER[[:space:]]+TABLE.*(ENABLE|DISABLE)[[:space:]]+TRIGGER|SP_FULLTEXT_DATABASE|CREATE[[:space:]]+FULLTEXT|SP_DB_VARDECIMAL_STORAGE_FORMAT|INSERT[[:space:]]+INTO|DELETE[[:space:]]+FROM|MERGE[[:space:]]+INTO|TRUNCATE[[:space:]]+TABLE)/ || normalized ~ /^[[:space:]]*UPDATE[[:space:]]/) {
        # Note: UPDATE is anchored to the start of the batch so FK clauses
        # like "ON UPDATE CASCADE" are not mistaken for a data-only UPDATE statement.
        # Omit security, storage/settings, full-text, and data-only batches.
      } else {
        # Modules using CHANGETABLE(CHANGES ...) fail to compile unless change
        # tracking is already enabled, which source dumps often omit.
        if (normalized ~ /CHANGETABLE/) {
          ensure_change_tracking(batch)
        }
        printf "%s", batch
        if (batch !~ /\n$/) {
          print ""
        }
        print "GO"
      }

      batch = ""
    }

    function ensure_change_tracking(text,    search, frag) {
      # CHANGETABLE requires database change tracking and table-level tracking
      # to be enabled before dependent modules are compiled.
      if (!ct_db_enabled) {
        print "ALTER DATABASE CURRENT SET CHANGE_TRACKING = ON (CHANGE_RETENTION = 2 DAYS, AUTO_CLEANUP = ON)"
        print "GO"
        ct_db_enabled = 1
      }
      search = text
      while (match(search, /CHANGETABLE[[:space:]]*\([[:space:]]*CHANGES[[:space:]]+[][A-Za-z0-9_.]+/)) {
        frag = substr(search, RSTART, RLENGTH)
        sub(/^CHANGETABLE[[:space:]]*\([[:space:]]*CHANGES[[:space:]]+/, "", frag)
        if (!(frag in ct_tables_enabled)) {
          printf "ALTER TABLE %s ENABLE CHANGE_TRACKING\n", frag
          print "GO"
          ct_tables_enabled[frag] = 1
        }
        search = substr(search, RSTART + RLENGTH)
      }
    }

    # SQL Server permits an optional repeat count and trailing comment on GO.
    /^[[:space:]]*[Gg][Oo]([[:space:]]+[0-9]+)?[[:space:]]*(--.*)?$/ {
      emit_batch()
      next
    }

    { batch = batch $0 "\n" }

    END { emit_batch() }
  ' > "$output_script"

  echo "Converted $(basename "$source_script")"
done

