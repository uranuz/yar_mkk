module mkk_site.view_service.ivy_custom;

import ivy, ivy.compiler, ivy.interpreter, ivy.common, ivy.interpreter_data;

class RecordSetRange: IDataNodeRange
{
	alias TDataNode = DataNode!string;
private:
	TDataNode _rawRS;
	TDataNode _rawFormat;
	TDataNode _rawData;
	size_t[string] _namesMapping;
	size_t i = 0;

public:
	this(TDataNode rawRS)
	{
		_rawRS = rawRS;
		assert( "t" in rawRS, `Expected type field "t" in recordset raw data!` );
		assert( "d" in rawRS, `Expected data field "d" in recordset raw data!` );
		assert( "f" in rawRS, `Expected format field "f" in recordset raw data!` );

		assert( rawRS["t"].type == DataNodeType.String && rawRS["t"].str == "recordset", `Expected "recordset" value in "t" field` );
		_rawFormat = _rawRS["f"];
		_rawData = _rawRS["d"];

		foreach( i, fmt; _rawFormat.array ) {
			_namesMapping[ fmt["n"].str ] = i;
		}
	}

	override {
		bool empty() @property
		{
			import std.range: empty;
			return i >= _rawData.array.length;
		}

		TDataNode front()
		{
			TDataNode dataDict;
			dataDict["d"] = _rawData.array[i];
			dataDict["f"] = _rawFormat;
			dataDict["_mapping"] = TDataNode(_namesMapping);

			return dataDict;
		}

		void popFront() {
			++i;
		}

		DataNodeType aggrType() @property
		{
			return DataNodeType.Array;
		}
	}
}

// Just creates RecordSetRange from raw record data passed in rawRS parameter
class RawRSRangeInterpreter: INativeDirectiveInterpreter
{
	override void interpret(Interpreter interp)
	{
		import std.range: back, popBack;

		interp._stack ~= TDataNode(new RecordSetRange(interp.getValue("rawRS")));
	}

	private __gshared DirAttrsBlock!(true)[] _compilerAttrBlocks;
	private __gshared DirAttrsBlock!(false)[] _interpAttrBlocks;
	private __gshared DirectiveDefinitionSymbol _symbol;
	
	shared static this()
	{
		import std.algorithm: map;
		import std.array: array;

		_compilerAttrBlocks = [
			DirAttrsBlock!true(DirAttrKind.ExprAttr, [
				DirValueAttr!(true)("rawRS", "any")
			]),
			DirAttrsBlock!true(DirAttrKind.BodyAttr)
		];

		_interpAttrBlocks = _compilerAttrBlocks.map!( a => a.toInterpreterBlock() ).array;
		_symbol = new DirectiveDefinitionSymbol("rsRange", _compilerAttrBlocks);
	}

	override DirAttrsBlock!(false)[] attrBlocks() @property {
		return _interpAttrBlocks;
	}

	override Symbol compilerSymbol() @property {
		return _symbol;
	}
}
