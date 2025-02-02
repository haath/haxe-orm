package hant;

import sys.io.Process;
import haxe.Json;
import sys.FileSystem;
import sys.io.File;
using stdlib.StringTools;

class Haxelib
{
	static var globalRepoPath : String;
	static var pathCache = new Map<String, String>();

	public static function getPath(lib:String, ?projectDir:String) : String
	{
		if (lib == "std") return getStdPath();

		if (pathCache.exists(lib + "|" + projectDir)) return pathCache.get(lib + "|" + projectDir);

		var repo = getRepoPath(projectDir);

		var ver : String = null;
		if (lib.indexOf(":") >= 0)
		{
			ver = lib.split(":")[1];
			lib = lib.split(":")[0];
		}

		var base = repo + "/" + lib;

		if (!FileSystem.exists(base)) return null;

		var path : String = null;

		if (ver == null)
		{
			if (FileSystem.exists(base + "/.dev"))
			{
				path = File.getContent(base + "/.dev").trim();
			}
			else
			{
				if (!FileSystem.exists(base + "/.current")) return null;
				path = repo + "/" + lib + "/" + File.getContent(base + "/.current").trim().replace(".", ",");
			}
		}
		else
		{
			path = repo + "/" + lib + "/" + ver.trim().replace(".", ",");
		}

		if (!FileSystem.exists(path)) return null;

		if (FileSystem.exists(path + "/haxelib.json"))
		{
			var info = Json.parse(File.getContent(path + "/haxelib.json"));
			if (info.classPath != null) path = Path.join([ path, info.classPath ]);
		}

		path = Path.normalize(path);

		pathCache.set(lib, path);

		return path;
	}

	public static function getStdPath()
	{
		var haxeStdPath = Sys.getEnv("HAXE_STD_PATH");
		if (haxeStdPath != null && haxeStdPath != "") return Path.normalize(haxeStdPath);
		var haxePath = Sys.getEnv("HAXEPATH");
		if (haxePath != null && haxePath != "") return Path.normalize(Path.join([ haxePath, "std" ]));
		return Sys.systemName() == "Windows" ? "C:/HaxeToolkit/haxe/std" : "/usr/share/haxe/std";
	}

	public static function getRepoPath(?projectDir:String) : String
	{
		var localRepoPath = projectDir != null && projectDir != "" ? Path.join([ projectDir, ".haxelib"]) : ".haxelib";
		return FileSystem.exists(localRepoPath) ? localRepoPath : getGlobalRepoPath();
	}

	public static function getGlobalRepoPath() : String
	{
		if (globalRepoPath == null)
		{
            var proc: Process = new Process("haxelib", [ "--global", "config" ]);
            proc.exitCode();
			globalRepoPath = Path.removeTrailingSlashes(proc.stdout.readAll().toString().trim());
		}
		return globalRepoPath;
	}
}