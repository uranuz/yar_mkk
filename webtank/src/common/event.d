module webtank.common.event;

enum EventOption
{	synchronized_,
	allowDuplicateHandlers,
	stopOnValue,
	stopHandlingValue,
};

template OptionPair(alias first, alias second)
{	enum type = first;
	enum value = second;
}

///Option that signals whether to sunchronize access to ErrorEvent object
template Synchronized(bool value)
{	alias OptionPair!(EventOption.synchronized_, value) Synchronized;
}

///Option that signals whether duplicate handlers are allowed
template AllowDuplicateHandlers(bool value)
{	alias OptionPair!(EventOption.allowDuplicateHandlers, value) AllowDuplicateHandlers;
}

///Option defines return value that signals handling interrupt
///Interrupting doesn't affect priorite handers
template StopHandlingValue(alias value)
{	alias OptionPair!(EventOption.stopHandlingValue, value) StopHandlingValue;
}

template GetEventOption(EventOption optType, Opts...)
{	static if( Opts.length > 0 )
	{	static if( is( typeof(Opts[0].type) == EventOption ) )
		{	static if( Opts[0].type == EventOption.stopHandlingValue && optType == EventOption.stopOnValue )
				enum bool GetEventOption = true;
			else static if( Opts[0].type == optType )
				enum GetEventOption = Opts[0].value;
			else
				enum GetEventOption = GetEventOption!(optType, Opts[1..$]);
		}
	 	else
			enum GetEventOption = GetEventOption!(optType, Opts[1..$]);
	}
 	else
	{	static if( optType == EventOption.synchronized_ )
			enum bool GetEventOption = false;
	 	else static if( optType == EventOption.allowDuplicateHandlers )
			enum bool GetEventOption = true;
		else static if( optType == EventOption.stopOnValue )
			enum bool GetEventOption = false;
	 	else
			static assert( 0, "Can't get default value for ErrorEvent option");
	}
}

import std.traits : isCallable, isDelegate;

struct Event(Opts...)
	if (Opts.length >= 1 && Opts.length <= 3 && isCallable!(Opts[0]))
{
	import std.functional : toDelegate;
	import std.traits : ParameterTypeTuple;

	static if (Opts.length >= 2)
	{
		static if (!is(typeof(Opts[1]) == bool))
			static assert(0, "Expected a bool representing whether to allow duplicates!");
		public enum allowDuplicates = Opts[1];
	}
	else
		public enum allowDuplicates = false;

	static if (Opts.length >= 3)
	{
		static if( !is(typeof(Opts[2]) == bool))
			static assert(0, "Expected a bool representing whether to synchronize access!");
		public enum isSynchronized = Opts[2];
	}
	else
		public enum isSynchronized = false;

	static if (isDelegate!(Opts[0]) || isFunction!(Opts[0]))
		public alias DelegateType = Opts[0];
	else
		public alias DelegateType = typeof(&Opts[0]);

	private DelegateType[] subscribedCallbacks;
	
	static if (isSynchronized)
		private Object lock = new Object();
	private R MaybeSynchronous(R)(R delegate() d)
	{
		static if (isSynchronized)
		{
			synchronized (lock)
			{
				return d();
			}
		}
		else
			return d();
	}
	
	void opOpAssign(string op : "~", C)(C value)
		if (isCallable!C && !isDelegate!C)
	{
		this ~= toDelegate(value);
	}
	void opOpAssign(string op : "~")(DelegateType value)
	{
		MaybeSynchronous({
			import std.algorithm : canFind;
			
			if (!allowDuplicates && subscribedCallbacks.canFind(value))
				throw new Exception("Attempted to subscribe the same callback multiple times!");
			subscribedCallbacks ~= value;
		});
	}
	
	
	void opOpAssign(string op : "-", C)(C value)
		if (isCallable!C && !isDelegate!C)
	{
		this -= toDelegate(value);
	}
	void opOpAssign(string op : "-")(DelegateType value)
	{
		MaybeSynchronous({
			import std.algorithm : countUntil, remove;
			
			auto idx = subscribedCallbacks.countUntil(value);
			if (idx == -1)
				throw new Exception("Attempted to unsubscribe a callback that was not subscribed!");
			subscribedCallbacks = subscribedCallbacks.remove(idx);
		});
	}
	
	private static void rethrowExceptionHandler(DelegateType invokedCallback, Exception exceptionThrown) { throw exceptionThrown; }
	auto fire(ParameterTypeTuple!DelegateType args, void delegate(DelegateType, Exception) exceptionHandler = toDelegate(&rethrowExceptionHandler))
	{
		return MaybeSynchronous({
			import std.traits : ReturnType;
			
			static if (is(ReturnType!DelegateType == void))
			{
				foreach (callback; subscribedCallbacks)
				{
					try
					{
						callback(args);
					}
					catch (Exception e)
					{
						exceptionHandler(callback, e);
					}
				}
			}
			else
			{	ReturnType!DelegateType[] retVals;
				
				foreach (callback; subscribedCallbacks)
				{
					try
					{
						retVals ~= callback(args);
					}
					catch (Exception e)
					{
						exceptionHandler(callback, e);
					}
				}
				
				return retVals;
			}
		});
	}
}

import std.stdio, std.algorithm, std.range, std.conv, std.container, std.typecons, std.typetuple, std.traits;

bool isInheritsOf( TypeInfo_Class objTypeinfo, TypeInfo_Class baseTypeinfo  )
{	while( objTypeinfo )
	{	if( objTypeinfo is baseTypeinfo )
			return true;

		objTypeinfo = objTypeinfo.base;
	}
	return false;
}

///Error handling event-like mechanics
struct ErrorEvent( ErrorHandler, Opts... )
	if( isCallable!(ErrorHandler) )
{
	enum bool isSynchronized = GetEventOption!(EventOption.synchronized_, Opts);
	enum bool allowDuplicateHandlers = GetEventOption!(EventOption.allowDuplicateHandlers, Opts);
	enum bool stopHandlingOnValue = GetEventOption!(EventOption.stopOnValue, Opts);

	static if( stopHandlingOnValue )
		enum ReturnType!(ErrorHandler) stopHandlingValue = GetEventOption!(EventOption.stopHandlingValue, Opts);

	alias ParameterTypeTuple!(ErrorHandler) ParamTypes;

	struct ErrorHandlerPair
	{	ErrorHandler method;
		TypeInfo_Class typeInfo;
	}

	static if (isSynchronized)
		private Object lock = new Object();
	private R MaybeSynchronous(R)(R delegate() d)
	{	static if (isSynchronized)
		{	synchronized (lock)
			{
				return d();
			}
		}
		else
			return d();
	}

	bool fire(ParamTypes params)
	{	return MaybeSynchronous({
			_sortHandlers();

			static if( stopHandlingOnValue )
				bool stopFlag = false;

			foreach( pair; prioriteErrorPairs )
			{	if( typeid(params[0]).isInheritsOf(pair.typeInfo) )
				{	if( pair.method(params) )
					{	static if( stopHandlingOnValue )
							stopFlag = true;
					}
				}
			}

			static if( stopHandlingOnValue )
			{	if( stopFlag )
					return true;
			}

			foreach( pair; errorPairs )
			{	if( typeid(params[0]).isInheritsOf(pair.typeInfo) )
				{	static if( stopHandlingOnValue )
					{	if( pair.method(params) == stopHandlingValue  )
							return true;
					}
					else
					{	pair.method(params);
					}
				}
			}
			return false;
		});
	}

	private void _sortHandlers()
	{	MaybeSynchronous({
			sort!( (a, b) { return countDerivations(a.typeInfo) > countDerivations(b.typeInfo); } )( prioriteErrorPairs );
			sort!( (a, b) { return countDerivations(a.typeInfo) > countDerivations(b.typeInfo); } )( errorPairs );
		});
	}

	void join()(TypeInfo_Class errorTypeinfo, ErrorHandler handler, bool isPriorite = false)
	{	MaybeSynchronous({
			if( isPriorite )
			{	prioriteErrorPairs ~= ErrorHandlerPair( handler, errorTypeinfo );
			}
			else
			{	errorPairs ~= ErrorHandlerPair( handler, errorTypeinfo );
			}
		});
	}

	void join(SomeErrorHandler)(SomeErrorHandler handler, bool isPriorite = false)
		if( isCallable!(SomeErrorHandler) && is( ParameterTypeTuple!(SomeErrorHandler)[0] : ParamTypes[0] ) )
	{	alias ParameterTypeTuple!(SomeErrorHandler)[0] SomeError;
		this.join(
			typeid(SomeError),
			(ParamTypes params)
			{	static if( !is ( ReturnType!(ErrorHandler) == void )  )
					return handler( cast(SomeError) params[0], params[1..$] );
				else
					handler( cast(SomeError) params[0], params[1..$] );
			},
			isPriorite
		);
	}

protected:
	ErrorHandlerPair[] prioriteErrorPairs;
	ErrorHandlerPair[] errorPairs;
}

size_t countDerivations(TypeInfo_Class typeInfo)
{	size_t result;
	while(typeInfo !is null)
	{	//writeln(typeInfo.name);
		result ++;
		typeInfo = typeInfo.base;
	}
	return result;
}