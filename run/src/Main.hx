import hant.FlashDevelopProject;
import hant.Path;
import stdlib.Exception;
import neko.Lib;
import hant.Log;
import orm.Db;
import hant.CmdOptions;
using StringTools;

class Main 
{
	static function main()
	{
		Log.instance.depthLimit = 2;
		
		var exeDir = Path.normalize(Sys.getCwd());
        
		var args = Sys.args();
		if (args.length > 0)
		{
			Sys.setCwd(args.pop());
		}
		else
		{
			fail("run this program via haxelib utility.");
		}
		
		var options = new CmdOptions();
		
		options.add("databaseConnectionString", "", null,
			"Database connecting string like 'mysql://user:pass@localhost/mydb'.");
		
		options.add("hxproj", "", [ "-p", "--hxproj" ], 
			  "Path to the FlashDevelop *.hxproj file.\n"
			+ "Used to detect class paths.\n"
			+ "If not specified then *.hxproj from the current folder will be used.");
		
		options.add("autogenPackage", "models.autogenerated", [ "-a", "--autogenerated-package" ],
			  "Package name for autogenerated classes.\n"
			+ "Default is 'models.autogenerated'.");
		
		options.add("customPackage", "models", [ "-c", "--custom-package" ],
			  "Package name for your custom classes.\n"
			+ "Default is 'models'.");
		
		options.add("srcPath", "", [ "-s", "--src-path" ],
			  "Path to your source files directory.\n"
			+ "This is a base path for generated files.\n"
			+ "Read last src path from the project file if not specified.");
		
		options.addRepeatable("ignoreTables", String, [ "-i", "--ignore-table" ],
			  "Table name to ignore.");
		
		options.addRepeatable("noInstantiateManagers", String, [ "-nim", "--no-instantiate-manager" ], 
			  "Table name to skip manager creating in autogenerated Orm class.\n"
			+ "You can use this switch for your managers with a custom constructors.\n"
			+ "In this case you must instantiate these managers manually\n"
			+ "(in regular case - in your custom Orm constructor).");
		
		options.parse(args);
        
		if (args.length > 0)
		{
			try
			{
				var srcPath = options.get("srcPath");
				
				var project = FlashDevelopProject.load(options.get("hxproj"));
				if (project == null) project = new FlashDevelopProject();
				
				if (srcPath == "")
				{
					srcPath = project.classPaths.length > 0
						? project.classPaths[project.classPaths.length - 1]
						: "src";
				}
				
				if (project.classPaths.indexOf(srcPath) < 0)
				{
					project.classPaths.push(srcPath);
				}
				
				var databaseConnectionString = options.get("databaseConnectionString");
				if (databaseConnectionString != "")
				{
					Log.start("Generate object related mapping classes");
					new OrmGenerator(project, srcPath).generate(new Db(databaseConnectionString), options.get("autogenPackage"), options.get("customPackage"), options.get("ignoreTables"), options.get("noInstantiateManagers"));
					Log.finishSuccess();
				}
				else
				{
					fail("Database connection string must be specified.");
				}
					
			}
			catch (e:Exception)
			{
				Log.echo(e.message);
				fail();
			}
        }
		else
		{
			
			Lib.println("Generating set of the haxe classes from database tables.");
			Lib.println("\nUsage:\n\thaxelib run orm <databaseConnectionString> [options]");
			Lib.println("\nOptions:\n");
			Lib.println(options.getHelpMessage());
		}
        
        Sys.exit(0);
	}
	
	static function fail(?message:String)
	{
		if (message != null)
		{
			Lib.println("ERROR: " + message);
		}
		Sys.exit(1);
	}
}