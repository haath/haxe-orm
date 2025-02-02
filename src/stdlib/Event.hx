package stdlib;

class Event<EventArgsType>
{
	var target : Dynamic;
	var handlers : Array<Dynamic->EventArgsType->Void>;
	
	public function new(target:Dynamic) 
	{
		this.target = target;
		handlers = [];
	}
	
	public function bind(handler:Dynamic->EventArgsType->Void) : Void
	{
		handlers.push(handler);
	}
	
	public function unbind(handler:Dynamic->EventArgsType->Void) : Void
	{
		while (handlers.remove(handler)) {};
	}
	
	public function unbindAll()
	{
		handlers = [];
	}
	
	public function call(args:EventArgsType) : Void
	{
		for (handler in handlers)
		{
			Reflect.callMethod(null, handler, [ target, args ]);
		}
	}
}