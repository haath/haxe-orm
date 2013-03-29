package ;

import hant.PathTools;
import hant.FlashDevelopProject;
import stdlib.FileSystem;
import orm.Db;
import hant.Log;
import haxe.io.Path;
import sys.io.File;
using stdlib.StringTools;

class OrmModelGenerator 
{
	public static function make(log:Log, project:FlashDevelopProject, db:Db, table:String, customModelClassName:String, autogenModelClassName:String, customManagerClassName:String) : Void
	{
		log.start(table + " => " + customModelClassName);
		
		var basePath = PathTools.path2normal(project.srcPath) + "/";
		
		var vars = OrmTools.fields2vars(db.connection.getFields(table));
		
		var autogenModel = getAutogenModel(table, vars, autogenModelClassName);
		var destFileName = basePath + autogenModelClassName.replace(".", "/") + ".hx";
		FileSystem.createDirectory(Path.directory(destFileName));
		File.saveContent(
			  destFileName
			, "// This is autogenerated file. Do not edit!\n\n" + autogenModel.toString()
		);
		
		if (project.findFile(customModelClassName.replace(".", "/") + ".hx") == null) 
		{
			var customModel = getCustomModel(table, vars, customModelClassName, autogenModelClassName, customManagerClassName);
			var destFileName = basePath + customModelClassName.replace(".", "/") + ".hx";
			FileSystem.createDirectory(Path.directory(destFileName));
			File.saveContent(destFileName, customModel.toString());
		}
		
		log.finishOk();
	}
	
	static function getAutogenModel(table:String, vars:List<OrmHaxeVar>, modelClassName:String, baseClassName:String=null) : HaxeClass
	{
		var model = new HaxeClass(modelClassName, baseClassName);
		
		model.addVar({ haxeName:"db", haxeType:"orm.Db", haxeDefVal:null }, true);
		
		for (v in vars)
		{
			model.addVar(v);
		}
		
		model.addMethod("new", [ { haxeName:"db", haxeType:"orm.Db", haxeDefVal:null } ], "Void", "this.db = db;");
        
        if (Lambda.exists(vars, function(v) return v.isKey) && Lambda.exists(vars, function(v) return !v.isKey))
		{
			var settedVars = Lambda.filter(vars, function(v) return !v.isKey && !v.isAutoInc);
			if (settedVars.length > 0)
			{
				model.addMethod("set", settedVars, "Void",
					Lambda.map(settedVars, function(v) return "this." + v.haxeName + " = " + v.haxeName + ";").join("\n")
				);
			}
			
			var savedVars = Lambda.filter(vars, function(v) return !v.isKey);
			var whereVars = Lambda.filter(vars, function(v) return v.isKey);
			model.addMethod("save", new List<OrmHaxeVar>(), "Void",
				  "db.query(\n"
				    + "\t 'UPDATE `" + table + "` SET '\n"
					+ "\t\t+  '" + Lambda.map(savedVars, function(v) return "`" + v.name + "` = ' + db.quote(" + v.haxeName + ")").join("\n\t\t+', ")
					+ "\n\t+' WHERE " 
					+ Lambda.map(whereVars, function(v) return "`" + v.name + "` = ' + db.quote(" + v.haxeName + ")").join("+' AND ")
					+ "\n\t+' LIMIT 1'"
				+ "\n);"
			);
		}
		
		return model;
	}

	static function getCustomModel(table:String, vars:List<OrmHaxeVar>, customModelClassName:String, autogenModelClassName:String, customManagerClassName:String) : HaxeClass
	{
		return new HaxeClass(customModelClassName, autogenModelClassName);
	}
}