#!/usr/bin/env bash
# Initialize the SQL Server database used by the Docker Compose stack.
#
# The mssql-init service runs this script after the mssql service is healthy.
# Converted schema files are mounted read-only at /db-init, and the SQL Server
# administrator password is supplied through MSSQL_SA_PASSWORD. DATABASE_NAME
# optionally identifies the target database; an empty value leaves the script
# operating against the server's default context.
#
# Initialization is intentionally idempotent. A marker table records a
# completed import. If the target database already exists without that marker,
# the script assumes it was initialized elsewhere and skips importing files.
# Otherwise, every .sql file in /db-init is executed and the marker is created.
set -euo pipefail

# -b makes sqlcmd fail the script on SQL errors; -C accepts the container's
# certificate; the remaining options connect as the SQL Server administrator.
sqlcmd=(/opt/mssql-tools18/bin/sqlcmd -b -C -S mssql -U sa -P "$MSSQL_SA_PASSWORD")
# Keep the marker in master so the initialization state is visible regardless
# of which target database is selected for the import.
marker_table="master.dbo.__schemaspy_mssql_initialized"
database_name="${DATABASE_NAME:-}"
# Escape apostrophes before interpolating DATABASE_NAME into a T-SQL literal.
escaped_database_name="${database_name//\'/\'\'}"

# A marker means a previous run completed successfully, so do not rerun the
# schema scripts when the one-shot service is restarted.
is_initialized="$("${sqlcmd[@]}" -h -1 -W -Q "SET NOCOUNT ON; SELECT CASE WHEN OBJECT_ID(N'${marker_table}', N'U') IS NULL THEN 0 ELSE 1 END")"
if [[ "$is_initialized" == "1" ]]; then
  echo "SQL Server schema is already initialized; skipping import."
  exit 0
fi

# If a named database already exists but has no marker, it was not created by
# this initializer. Leave it untouched rather than importing into an unknown
# or potentially non-empty database.
if [[ -n "$database_name" && "$database_name" != "master" ]]; then
  database_exists="$("${sqlcmd[@]}" -h -1 -W -Q "SET NOCOUNT ON; SELECT CASE WHEN DB_ID(N'${escaped_database_name}') IS NULL THEN 0 ELSE 1 END")"
  if [[ "$database_exists" == "1" ]]; then
    "${sqlcmd[@]}" -Q "CREATE TABLE ${marker_table} (initialized_at datetime2 NOT NULL DEFAULT SYSUTCDATETIME())"
    echo "SQL Server database ${database_name} already exists; skipping import."
    exit 0
  fi
fi

# sqlcmd receives each converted file in filename order. The glob naturally
# skips an empty mounted directory because non-files are ignored below.
for script in /db-init/*.sql; do
  [[ -f "$script" ]] || continue
  "${sqlcmd[@]}" -i "$script"
done

# Only record success after every input script has completed without error.
"${sqlcmd[@]}" -Q "CREATE TABLE ${marker_table} (initialized_at datetime2 NOT NULL DEFAULT SYSUTCDATETIME())"
echo "SQL Server schema initialization complete."
