# SchemaSpy

Quickly run SchemaSpy on a Postgres, MySQL, or SQLite3 database in order
to generate a browsable visualization of the tables, columns, and relationships.

Based on `openjdk:jre-alpine` the resulting image generates the database documentation using SchemaSpy and serves the resulting html using Caddy, and is compatible with OpenShift.

The open source SchemaSpy project is located here: https://github.com/schemaspy/schemaspy

The open source Caddy project is located here; https://github.com/mholt/caddy

## Configuration

Configuration is performed using environment varables.

| Name | Description | Example |
| ---- | ------- | ------- |
| DATABASE_TYPE | The database type being documented.  Defaults to `pgsql`. | One of `mysql`, `pgsql`, or `sqlite`.  Other database types are supported by SchemaSpy, but their JDBC connector libraries are not currently included in the image. |
| DATABASE_NAME | The name of the database to document. | MyDatabase |
| DATABASE_HOST | The hostname of the server |  postgresql |
| DATABASE_SCHEMA | OPTIONAL - The schema in the database to document.  Defaults to `public`. | my_schema |
| DATABASE_CATALOG | OPTIONAL - The catalog in the database to document.  With some databases this is used to define the name of the database. | my_catalog |
| DATABASE_DRIVER | OPTIONAL - Used to override the default JDBC driver.  The scripts attempt to set the driver base on convention using `DATABASE_TYPE` | /app/lib/pgsql-jdbc.jar |
| DATABASE_USER | The username to use when logging into the database.  When using OpenShift this should be configured as a secrete. |  my_user |
| DATABASE_PASSWORD | The password to use when logging into the database.  When using OpenShift this should be configured as a secrete.|  my_password |
| SCHEMASPY_ARGUMENTS | OPTIONAL - Allows you to define additional command line arguments for SchemaSpy |  `-hq` to generate high quality output. |
| SCHEMASPY_COMMAND_OVERRIDE | OPTIONAL - Use this to override the SchemaSpy commands and define the commands explicitly.  This is intended as a testing and troubleshooting tool. | `lib/schemaspy.jar -t "pgsql" -db "TheOrgBook_Database" -dp "lib/postgresql-jdbc.jar" -hq -s "public" -u "TheOrgBook_User" -p "*****" -host "postgresql" -o /var/www/html` |
| SCHEMASPY_PORT | OPTIONAL - Defaults to `8080`.  Changing this requires additional code and configuration changes, so it's best to leave it alone. | `8080` |
| OUTPUT_PATH | OPTIONAL - The output folder for the documentation.  Defaults to `/var/www/html`, which is used by Caddy.  Changing this requires additional code and configuration changes, so it's best to leave it alone. | `/var/www/html` |
| SCHEMASPY_PATH | OPTIONAL - The path to the SchemaSpy jar file.  Defaults to `lib/schemaspy.jar`.  Changing this requires additional code and configuration changes, so it's best to leave it alone. |  `lib/schemaspy.jar` |

## Configuration - Backward Compatibility

The following environment variables are provided for drop-in backward compatibility with the previous SchemaSpy container implementation that only supported PostgreSQl databases (https://github.com/bcgov/SchemaSpy).

| Name | Description | Example |
| ---- | ------- | ------- |
| DATABASE_SERVICE_NAME | Use `DATABASE_HOST` moving forward.  The hostname of the server |  postgresql |
| POSTGRESQL_USER | Use `DATABASE_USER` moving forward.  The username to use when logging into the database.  When using OpenShift this should be configured as a secrete. |  my_user |
| POSTGRESQL_PASSWORD | Use `DATABASE_PASSWORD` moving forward.  The password to use when logging into the database.  When using OpenShift this should be configured as a secrete.|  my_password |
| POSTGRESQL_DATABASE | Use `DATABASE_NAME` moving forward.  The name of the database to document. | MyDatabase |

## Running in OpenShift

The Dockerfile was designed to generate an image that can be used in OpenShift.

As a quick-start (example), the following command will create a BuildConfig, DeploymentConfig, and ancillary resources (service, etc.) in your current OpenShift project.

```
oc new-app https://github.com/bcgov/SchemaSpy -e DATABASE_TYPE=pgsql -e DATABASE_NAME=default -e DATABASE_HOST=postgresql -e DATABASE_USER=django -e DB_PASSWORD=xyz1234 
```

For more a more structured build and deployment environment, OpenShift templates can be found in the [OpenShift templates](./openshift/templates) folder.

## Running in Docker

### Build Command

```
docker build -t schemaspy https://github.com/bcgov/SchemaSpy
```

### Sample MySQL Usage

```
docker run -ti --rm --name schemaspy \
	-p 8080:8080 \
	-e DATABASE_TYPE=mysql \
	-e DATABASE_HOST=mysql -e DATABASE_NAME=mydatabase \
	-e DATABASE_USER=root -e DATABASE_PASSWORD=mysecretpassword \
	--link mysql \
	schemaspy
```

### Sample Postgres Usage

```
docker run -ti --rm --name schemaspy \
	-p 8080:8080 \
	-e DATABASE_TYPE=pgsql \
	-e DATABASE_HOST=postgres -e DATABASE_NAME=mydatabase \
	-e DATABASE_USER=postgres -e DATABASE_PASSWORD=mysecretpassword \
	--link postgres \
	schemaspy
```

### Sample SQLite3 Usage

```
mkdir data && cp mydatabase.sqlite3 data/
docker run -ti --rm --name schemaspy \
	-p 8080:8080 \
	-v "$PWD/data":/app/data \
	-e DATABASE_TYPE=sqlite \
	-e DATABASE_NAME=/app/data/mydatabase.sqlite3 \
	schemaspy
```

## Use on other databases

### Oracle

Due to licensing limitations, the JDBC drivers for Oracle are not included in the build image.

Links to the drivers can be found here;
* http://www.oracle.com/technetwork/database/features/jdbc/index-091264.html
* A link to the latest (ojdbc8.jar) drivers can be found here; http://www.oracle.com/technetwork/database/features/jdbc/jdbc-ucp-122-3110062.html

Using the Oracle Thin drivers it is easy to connect to an Oracle database.

The following assumes you have (somehow) included the Oracle drivers in the image, and they have been copied into `/app/lib/` as `ora-jdbc.jar`; for example ojdbc8.jar has been copied into `/app/lib/ora-jdbc.jar`.

Configuration:

| Name | Value | Description |
| ---- | ------- | ------- |
| DATABASE_TYPE | orathin | |
| DATABASE_NAME | CUAT | The Oracle `SID` |
| DATABASE_SCHEMA | COLIN_MGR_UAT | The Oracle `Schema` |
| DATABASE_CATALOG | CUAT.bcgov | The Oracle `Listener Service Name` |
| DATABASE_USER | username | |
| DATABASE_PASSWORD | ***** | |
| DATABASE_HOST | hostname:portnumber | *Hostname and port number MUST be specified.* |
| DATABASE_DRIVER | lib/ora-jdbc.jar | |

The resulting SchemaSpy command looks something like this;
```
java -jar lib/schemaspy.jar -t "orathin" -db "CUAT" -dp "lib/ora-jdbc.jar" -s "COLIN_MGR_UAT" -cat "CUAT.bcgov" -u "username" -p "*****" -host "hostname:portnumber" -o /var/www/html
```

## Code of Conduct

Please refer to the [Code of Conduct](./CODE_OF_CONDUCT.md) 

## Contributing

What to add support for additional database types, or add additional features?

For information on how to contribute, refer to [Contributing](CONTRIBUTING.md)

## License

The source code contained in this repository is released under the [Apache License, Version 2.0](./LICENSE).