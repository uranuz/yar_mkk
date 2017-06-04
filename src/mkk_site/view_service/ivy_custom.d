module mkk_site.view_service.ivy_custom;

import ivy, ivy.compiler, ivy.interpreter, ivy.common, ivy.interpreter_data;

private void _deserializeFieldInplace(ref TDataNode fieldData, ref TDataNode format)
{
	import std.datetime: SysTime, Date;
	
	switch(format["t"].str)
	{
		case "date":
			fieldData = TDataNode(SysTime(Date.fromISOExtString(fieldData.str)));
			break;
		case "dateTime":
			fieldData = TDataNode(SysTime.fromISOExtString(fieldData.str));
			break;
		default:
			break;
	}
}

class RecordSetAdapter: IClassNode
{
	alias TDataNode = DataNode!string;
private:
	TDataNode _rawRS;
	size_t[string] _namesMapping;

public:
	this(TDataNode rawRS)
	{
		_rawRS = rawRS;
		_ensureRecordSet();

		foreach( i, fmt; _rawFormat.array )
		{
			assert( "n" in fmt, `Expected name field "n" in record raw format` );
			_namesMapping[ fmt["n"].str ] = i;
		}

		foreach( i, ref recData; _rawData.array )
		{
			foreach( j, ref fieldData; recData.array ) {
				_deserializeFieldInplace(fieldData, _rawFormat[j]);
			}
		}
	}

	void _ensureRecordSet()
	{
		assert( "t" in _rawRS, `Expected type field "t" in recordset raw data!` );
		assert( "d" in _rawRS, `Expected data field "d" in recordset raw data!` );
		assert( "f" in _rawRS, `Expected format field "f" in recordset raw data!` );
		assert( _rawRS["t"].type == DataNodeType.String && _rawRS["t"].str == "recordset", `Expected "recordset" value in "t" field` );
	}

	TDataNode _rawData() @property {
		return _rawRS["d"];
	}

	TDataNode _rawFormat() @property {
		return _rawRS["f"];
	}

	static class Range: IDataNodeRange
	{
	private:
		RecordSetAdapter _rs;
		size_t i = 0;

	public:
		this(RecordSetAdapter recordSet) {
			_rs = recordSet;
		}

		override {
			bool empty() @property
			{
				import std.range: empty;
				return i >= _rs._rawData.array.length;
			}

			TDataNode front() {
				return _rs._makeRecord(i);
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

	private TDataNode _makeRecord(size_t index)
	{
		return TDataNode(new RecordAdapter(
			TDataNode([
				"d": _rawData.array[index],
				"f": _rawFormat,
				"t": TDataNode("record")
			]),
			_namesMapping
		));
	}

	override IDataNodeRange opSlice() {
		return new Range(this);
	}

	override TDataNode opIndex(size_t index) {
		return _makeRecord(index);
	}

	override TDataNode opIndex(string key) {
		assert(false, `Indexing by string key is not supported for RecordSetAdapter`);
	}

	override TDataNode __getAttr__(string attrName)
	{
		switch(attrName)
		{
			case "format": return _rawFormat;
			case "namesMapping": return TDataNode(_namesMapping);
			default: break;
		}
		return TDataNode();
	}

	override void __setAttr__(TDataNode node, string attrName) {
		assert(false, `Not attributes setting is yet supported by RecordSetAdapter`);
	}
}

class RecordAdapter: IClassNode
{
	alias TDataNode = DataNode!string;
private:
	TDataNode _rawRec;
	size_t[string] _namesMapping;

public:
	this(TDataNode rawRec, size_t[string] namesMapping)
	{
		_rawRec = rawRec;
		_ensureRecord();
		_namesMapping = namesMapping;
		_deserializeInplace();
	}

	this(TDataNode rawRec)
	{
		_rawRec = rawRec;
		_ensureRecord();

		foreach( i, fmt; _rawFormat.array )
		{
			assert( "n" in fmt, `Expected name field "n" in record raw format` );
			_namesMapping[ fmt["n"].str ] = i;
		}
		_deserializeInplace();
	}

	void _ensureRecord()
	{
		assert( "t" in _rawRec, `Expected type field "t" in record raw data!` );
		assert( "d" in _rawRec, `Expected data field "d" in record raw data!` );
		assert( "f" in _rawRec, `Expected format field "f" in record raw data!` );
		assert( _rawRec["t"].type == DataNodeType.String && _rawRec["t"].str == "record", `Expected "record" value in "t" field` );
	}

	void _deserializeInplace()
	{
		foreach( i, ref fieldData; _rawData.array ) {
			_deserializeFieldInplace(fieldData, _rawFormat[i]);
		}
	}

	TDataNode _rawData() @property {
		return _rawRec["d"];
	}

	TDataNode _rawFormat() @property {
		return _rawRec["f"];
	}

	static class Range: IDataNodeRange
	{
	private:
		RecordAdapter _rec;
		size_t i = 0;

	public:
		this(RecordAdapter record) {
			_rec = record;
		}

		override {
			bool empty() @property
			{
				import std.range: empty;
				return i >= _rec._rawData.array.length;
			}

			TDataNode front() {
				return _rec._rawData[i];
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

	override IDataNodeRange opSlice() {
		return new Range(this);
	}

	override TDataNode opIndex(size_t index) {
		return _rawData[index];
	}

	override TDataNode opIndex(string key) {
		return _rawData[ _namesMapping[key] ];
	}

	override TDataNode __getAttr__(string attrName)
	{
		switch(attrName)
		{
			case "format": return _rawFormat;
			case "namesMapping": return TDataNode(_namesMapping);
			default: break;
		}
		return TDataNode();
	}

	override void __setAttr__(TDataNode value, string attrName) {
		assert(false, `Not attributes setting is yet supported by RecordAdapter`);
	}
}

/+

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
+/