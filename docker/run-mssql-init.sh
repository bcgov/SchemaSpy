#!/usr/bin/env bash
set -euo pipefail

sqlcmd=(/opt/mssql-tools18/bin/sqlcmd -b -C -S mssql -U sa -P "$MSSQL_SA_PASSWORD")
marker_table="master.dbo.__schemaspy_mssql_initialized"
database_name="${DATABASE_NAME:-}"
escaped_database_name="${database_name//\'/\'\'}"

is_initialized="$("${sqlcmd[@]}" -h -1 -W -Q "SET NOCOUNT ON; SELECT CASE WHEN OBJECT_ID(N'${marker_table}', N'U') IS NULL THEN 0 ELSE 1 END")"
if [[ "$is_initialized" == "1" ]]; then
  echo "SQL Server schema is already initialized; skipping import."
  exit 0
fi

if [[ -n "$database_name" && "$database_name" != "master" ]]; then
  database_exists="$("${sqlcmd[@]}" -h -1 -W -Q "SET NOCOUNT ON; SELECT CASE WHEN DB_ID(N'${escaped_database_name}') IS NULL THEN 0 ELSE 1 END")"
  if [[ "$database_exists" == "1" ]]; then
    "${sqlcmd[@]}" -Q "CREATE TABLE ${marker_table} (initialized_at datetime2 NOT NULL DEFAULT SYSUTCDATETIME())"
    echo "SQL Server database ${database_name} already exists; skipping import."
    exit 0
  fi
fi

for script in /db-init/*.sql; do
  [[ -f "$script" ]] || continue
  "${sqlcmd[@]}" -i "$script"
done

"${sqlcmd[@]}" -Q "CREATE TABLE ${marker_table} (initialized_at datetime2 NOT NULL DEFAULT SYSUTCDATETIME())"
echo "SQL Server schema initialization complete."
