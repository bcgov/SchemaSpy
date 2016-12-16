var http = require('http');

var finalhandler = require('finalhandler');
var serveStatic = require('serve-static');

var exec = require('child_process').exec;
var child;

var database_host = process.env.DATABASE_SERVICE_NAME;
var database_user = process.env.POSTGRESQL_USER;
var database_password = process.env.POSTGRESQL_PASSWORD;
var database_name = process.env.POSTGRESQL_DATABASE;

// validate the parameters.

var validation_error = false;

if (!database_host)
{
	console.log ("ERROR - Environment variable DATABASE_SERVICE_NAME is empty.\n");
	validation_error = true;
}

if (!database_user)
{
	console.log ("ERROR - Environment variable POSTGRESQL_USER is empty.\n");
	validation_error = true;
}

if (!database_password)
{
	console.log ("ERROR - Environment variable POSTGRESQL_PASSWORD is empty.\n");
	validation_error = true;
}

if (!database_name)
{
	console.log ("ERROR - Environment variable POSTGRESQL_DATABASE is empty.\n");
	validation_error = true;
}

if (validation_error == false)
{

	var fs = require('fs');
	var dir = './output';

	if (!fs.existsSync(dir)){
		fs.mkdirSync(dir);
	}

	var serve = serveStatic(dir);

	var command = "java -jar schemaspy-6.0.0-jar-with-dependencies.jar -t pgsql -db "+ database_name + " -s public -host " + database_host + " -port 5432 -u " + database_user + " -p " + database_password + " -o " + dir + " -dp postgresql-9.4-1201.jdbc4.jar";

	// Generate the HTML.
	child = exec(command, function (error, stdout, stderr) {
	  console.log('stdout: ' + stdout);
	  console.log('stderr: ' + stderr);
	  if (error !== null) {
		console.log("ERROR - the following problem occured during execution of SchemaSpy: \n" + error);
	  }
	  else
	  {
			console.log ("Schema generation complete, launching HTTP server.\n");

			var server = http.createServer(function(req, res) {
				var done = finalhandler(req, res);
					serve(req, res, done);
			});

			server.listen(8080);
	  }
	});
}