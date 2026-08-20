# SchemaSpy Local Docker Environment

A self-contained Docker Compose stack for trying out SchemaSpy against a
Postgres, MySQL, or SQL Server database, complete with example schemas and a
one-command generated, browsable HTML documentation site.

## What's in the stack

| Service | Purpose |
| ------- | ------- |
| `schemaspy` | Builds the documentation and serves it over HTTP via Caddy. |
| `postgres` | Example/target Postgres database. |
| `mysql` | Example/target MySQL database. |
| `mssql` + `mssql-init` | Example/target SQL Server database. `mssql-init` is a one-shot job that loads schema scripts once `mssql` is healthy. |

Only one of the three databases is documented at a time - `DATABASE_TYPE`/`DATABASE_HOST` in `.env` tell the `schemaspy` service which one to connect to. All three database containers still start, since it's a fixed compose stack, but SchemaSpy only talks to the one selected.

## Prerequisites

* Docker and Docker Compose
* A bash shell (the `manage` script is a bash script; on Windows use Git Bash/WSL)

## Quick start

```bash
cd docker
cp .env.example .env    # if you haven't already - manage does this automatically too
./manage start
```

`./manage start` opens the generated documentation in your default browser at
http://localhost:8082 (or whatever `SCHEMASPY_EXPOSED_PORT` is set to).

When you're done:

```bash
./manage stop   # stop containers, keep data volumes and output
# or
./manage down   # stop and remove containers, volumes, and generated output
```

### `manage` command reference

| Command | Description |
| ------- | ----------- |
| `./manage build [--no-cache]` | Builds the SchemaSpy image. |
| `./manage start` (alias `up`) | Loads `.env`, creates the output directory, converts any MSSQL scripts, starts all services in the background, and opens the documentation in the default browser. |
| `./manage open` | Opens the documentation in the default browser. |
| `./manage stop` | Stops containers without deleting anything. Fastest way to pause and resume later. |
| `./manage down` (alias `rm`) | Stops containers and deletes volumes (database data), the SchemaSpy output directory, and any converted MSSQL scripts. Destructive - use `stop` if you want to keep your data. |

## Example: documenting the bundled example schemas

Each database service ships with an example schema (a small library-catalog
database with authors, genres, books, members, and loans) that is loaded
automatically the first time its data volume is created:

* Postgres: [db-init/postgres/01-schema.sql](./db-init/postgres/01-schema.sql)
* MySQL: [db-init/mysql/01-schema.sql](./db-init/mysql/01-schema.sql)
* SQL Server: [db-init/mssql/01-schema.sql](./db-init/mssql/01-schema.sql)

To try SchemaSpy against one of them:

1. Open `.env` and make sure the block for the database you want is
   uncommented, and the other database blocks are commented out. For example,
   to document the bundled MySQL example schema:

   ```dotenv
   DATABASE_TYPE=mysql
   DATABASE_HOST=mysql
   DATABASE_NAME=example
   DATABASE_SCHEMA=
   DATABASE_USER=example
   DATABASE_PASSWORD=example
   ```

2. Start the stack:

   ```bash
   ./manage start
   ```

3. Browse to http://localhost:8082 to see the generated documentation for
   the `example` database.

To switch to a different database engine later, update the `DATABASE_*`
block in `.env` and run `./manage start` again - the SchemaSpy container will
regenerate its documentation against the newly selected database. If you want
a completely clean start (fresh example data too), run `./manage down` first.

> Note: The example `.sql` scripts in `db-init/` are only run by
> Postgres/MySQL/SQL Server the *first* time their data volume is created. If
> you've already started the stack once, delete the relevant volume (or run
> `./manage down`) to have them re-run.

## Schema import: pointing at your own database scripts

Rather than the bundled example schemas, you can point each database service
at your own folder of `.sql` initialization scripts.

### Postgres / MySQL

Set `POSTGRES_INIT_SCRIPTS_DIR` and/or `MYSQL_INIT_SCRIPTS_DIR` in `.env` to
the path of a folder containing your `.sql` scripts:

```dotenv
POSTGRES_INIT_SCRIPTS_DIR=./db-init/postgres
MYSQL_INIT_SCRIPTS_DIR=/absolute/path/to/my/mysql-scripts
```

The folder is mounted read-only into the database container's standard
initialization directory (`/docker-entrypoint-initdb.d`), so scripts run in
filename order using the same mechanism as the official Postgres/MySQL
images. As with the example schemas, these only run the first time the
corresponding data volume is created - use `./manage down` (or delete the
named volume) to force a fresh import.

### SQL Server

SQL Server has no built-in `/docker-entrypoint-initdb.d` mechanism, so this
stack provides its own import path via the `mssql-init` one-shot service:

1. Set `MSSQL_INIT_SCRIPTS_DIR` in `.env` to the folder containing your
   `.sql` scripts (for example, scripts exported from SQL Server Management
   Studio):

   ```dotenv
   MSSQL_INIT_SCRIPTS_DIR=/path/to/my/sqlserver-scripts
   ```

2. Run `./manage start`. Before starting containers, `manage` runs
   [convert-mssql-schema.sh](./convert-mssql-schema.sh) against that folder,
   which:
   * Strips UTF-16LE/UTF-8 byte-order marks commonly emitted by SSMS.
   * Splits scripts on `GO` batch separators.
   * Drops `CREATE DATABASE` batches other than a plain `CREATE DATABASE <name>`.
   * Omits security (`CREATE USER`/`LOGIN`/`ROLE`), storage/settings, full-text,
     and data-only (`INSERT`/`UPDATE`/`DELETE`/`MERGE`/`TRUNCATE`) batches,
     since this stack is only interested in schema (tables, views,
     relationships) for documentation purposes.
   * Writes the resulting container-safe scripts to
     `MSSQL_CONVERTED_INIT_SCRIPTS_DIR` (default `./generated-mssql-init`).
3. The `mssql-init` service then runs every `.sql` file in that converted
   folder, in filename order, against the `mssql` service once it reports
   healthy. The scripts run once per SQL Server data volume; use
   `./manage down` to remove the volume and import them again.

> The converted output folder is regenerated and deleted on every
> `start`/`down` - never edit it directly, edit the scripts in
> `MSSQL_INIT_SCRIPTS_DIR` instead.

## Exporting and sharing the generated documentation

SchemaSpy writes its generated HTML documentation to `SCHEMASPY_OUTPUT_DIR`
(default `./output`), which is bind-mounted into the container and persists
on your host machine across restarts.

This means the generated documentation is a fully static, self-contained set
of HTML/CSS/JS/image files - once it's been generated you can:

* Zip up and share the `output` folder with someone who doesn't have Docker,
  the source database, or this project at all.
* Open `output/index.html` directly in a browser, no server required.
* Host it on any static file host (S3, GitHub Pages, an internal wiki, etc.).
* Commit it to a repository as a point-in-time snapshot of your schema.

No running container, database connection, or copy of SchemaSpy is required
to view or share the generated documentation after the fact - only the
contents of the output directory.

## Configuration reference

See the comments in [.env.example](./.env.example) for the full list of
supported environment variables, including per-database connection settings,
exposed ports, and script/output directory overrides.
