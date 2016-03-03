import hant.Log;
import hant.FlashDevelopProject;
import orm.Db;
import hant.Path;
import stdlib.FileSystem;
import sys.io.File;
using stdlib.StringTools;


class OrmGenerator
{
	var project : FlashDevelopProject;
	var srcPath : String;
	
	public function new(project:FlashDevelopProject, srcPath:String)
    {
		this.project = project;
		this.srcPath = Path.normalize(srcPath) + "/";
	}
	
	public function generate(db:Db, autogenPackage:String, customPackage:String, ignoreTables:Array<String>, noInstantiateManagers:Array<String>)
	{
		var autogenOrmClassName = autogenPackage + ".Orm";
		var customOrmClassName = customPackage + ".Orm";
		
		var tables = new Array<OrmTable>();
		
		for (tableName in db.connection.getTables())
        {
			if (ignoreTables.indexOf(tableName) >= 0) continue;
			
			var table = new OrmTable(tableName, autogenPackage, customPackage);
			new OrmModelGenerator(project).make(db, table, customOrmClassName, srcPath);
			new OrmManagerGenerator(project).make(db, table, customOrmClassName, srcPath);
			tables.push(table);
        }
		
		Log.start("MANAGERS => " + customOrmClassName);
		makeAutogenOrm(tables, autogenOrmClassName, customOrmClassName, noInstantiateManagers);
		makeCustomOrm(customOrmClassName, autogenOrmClassName);
		Log.finishSuccess();
    }
	
	
	function makeAutogenOrm(tables:Array<OrmTable>, autogenOrmClassName:String, customOrmClassName:String, noInstantiateManagers:Array<String>)
	{
		var autogenOrm = getAutogenOrm(tables, autogenOrmClassName, noInstantiateManagers);
		var destFileName = srcPath + autogenOrmClassName.replace(".", "/") + ".hx";
		FileSystem.createDirectory(Path.directory(destFileName));
		File.saveContent(
			 destFileName
			,"// This is autogenerated file. Do not edit!\n\n" + autogenOrm.toString()
		);
	}
	
	function makeCustomOrm(customOrmClassName:String, autogenOrmClassName:String)
	{
		if (project.findFile(customOrmClassName.replace(".", "/") + ".hx") == null)
		{
			var customOrm = getCustomOrm(customOrmClassName, autogenOrmClassName);
			var destFileName = srcPath + customOrmClassName.replace(".", "/") + ".hx";
			FileSystem.createDirectory(Path.directory(destFileName));
			File.saveContent(destFileName, customOrm.toString());
		}
	}
	
	function getAutogenOrm(tables:Array<OrmTable>, fullClassName:String, noInstantiateManagers:Array<String>) : HaxeClass
	{
		var clas = new HaxeClass(fullClassName);
		
		for (t in tables)
		{
			clas.addVar( { haxeName:t.varName, haxeType:t.customManagerClassName, haxeDefVal:null }, false, false, true);
		}
		
		clas.addMethod(
			  "new"
			, [
				{ haxeName:"db", haxeType:"orm.Db", haxeDefVal:null } 
			  ]
			, "Void"
			, tables
				.filter(function(t) return noInstantiateManagers.indexOf(t.tableName) < 0)
				.map(function(t) return "this." + t.varName + " = new " + t.customManagerClassName + "(db, cast this);")
				.join("\n")
		);
        
		return clas;
	}
	
	function getCustomOrm(fullClassName:String, autogenOrmClassName:String) : HaxeClass
	{
		return new HaxeClass(fullClassName, autogenOrmClassName);
	}
}
