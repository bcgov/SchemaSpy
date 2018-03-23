# Templates

Here you will find a set of handy set of templates you can use to deploy, build and deployment, configurations into OpenShift.

## [schema-spy-build.json](schema-spy-build.json)

An example of a generic build template.

## [schema-spy-deploy.json](schema-spy-deploy.json)

An example of a generic deployment template.

## [schema-spy-oracle-deploy.json](schema-spy-oracle-deploy.json)

An example of a deployment template for use with a custom instance for documenting an Oracle database.

## [schema-spy-oracle-basicauth-deploy.json](schema-spy-oracle-basicauth-deploy.json)

An example of how to add basic authentication to a SchemaSpy instance.  This one builds on top of the Oracle template.

## [Caddyfile](Caddyfile)

An example of the Caddyfile you would load into OpenShift as a config map when setting up an instance with basic authentication.

For additional details on how orchestrate and automate the process of deploying a protected instance of SchemaSpy refer to the information on [Deploying a Protected SchemaSpy Instance](https://github.com/bcgov/TheOrgBook/tree/master/tob-db#bc-registries-schemaspy-instance-schema-spy-oracle)