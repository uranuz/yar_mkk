module webtank.view_logic.record_set_view;

import std.conv;

import webtank.datctrl.field_type;
import webtank.datctrl.record_set;

struct RecordSetViewFormat
{	
	
}

enum FieldViewManner 
{	plainText, simpleControls }

enum FieldOutputMode 
{	none, hidden, visible }

struct FieldViewFormat
{	FieldViewManner viewManner;
	bool isVisible;
	bool isWriteable;
	string nullCellStr;
	
}
class RecordSetView
{	
//protected:
	FieldViewManner[] _viewManners;
	FieldOutputMode[] _outputModes;
	bool[] _writeableFlags;
	RecordSet _recordSet;
	bool _showHeader = true;
	
	string[] _HTMLClasses;
	string _HTMLTableClass;
	//string[] _nullCellStrings;
	//string[] _trueCellStrings; 
	//string[] _falseCellStrings;
	
	string _nullCellDefaultStr = `Не задано`;
	string _trueCellDefaultStr = `Да`;
	string _falseCellDefaultStr = `Нет`;

public:
	this( RecordSet recordSet )
	{	_recordSet = recordSet; }
	
	
	string getHTMLStr()
	{	string resultStr = `<table` ~ ( ( _HTMLTableClass.length > 0 ) ? (` class="` ~ _HTMLTableClass ~ `"`) : `` ) ~ `>`;
		resultStr ~= `<tr>`;
		if( _showHeader )
		{	for( int k = 0; k < _recordSet.fieldCount; ++k )
			{	if( ( _outputModes.length <= k ) || (_outputModes[k] == FieldOutputMode.none) ) //Не делаем вывод поля
					continue;
				resultStr ~= `<th>` ~ _recordSet.getField(k).name ~ `</th>`; 
			}
		}
		resultStr ~= `</tr>`;
		
		//TODO: Добавить окошечки для фильтрации, если надо
		foreach( rec; _recordSet )
		{	resultStr ~= `<tr>`;
			for( size_t j = 0; j <_recordSet.fieldCount; ++j )
			{	if( ( _outputModes.length <= j ) || (_outputModes[j] == FieldOutputMode.none) ) //Не делаем вывод поля
					continue;
				auto curCell = rec[j];
				auto curViewManner = ( j < _viewManners.length ) ? _viewManners[j] : FieldViewManner.plainText;
				bool curIsWriteable = ( j < _writeableFlags.length ) ? _writeableFlags[j] : false; //По-умолчанию не записываемый
				resultStr ~= `<td`
					~ ( ( (j < _HTMLClasses.length) && (_HTMLClasses[j].length > 0) ) ? (` class="` ~ _HTMLClasses[j] ~ `"`) : "" ) ~ `>`;
				with( FieldViewManner ) {
				switch( curViewManner )
				{	case plainText:
					{	if( curCell.isNull() )
							resultStr ~= _nullCellDefaultStr;
						else
							resultStr ~= curCell.getStr();
						break;
					}
					case simpleControls: 
					{	string nameAttribStr = ` name="` ~ _recordSet.getField(j).name ~ `_` ~ _recordSet._frontKey.to!string ~ `"`;
						if( curCell.type == FieldType.Int || curCell.type == FieldType.Str || curCell.type == FieldType.IntKey )
						{	resultStr ~= `<input type="text"` ~ nameAttribStr ~ ` value="`
								~ ( ( curCell.isNull() ) ? _nullCellDefaultStr : curCell.getStr ) ~`"` 
								~ ( ( !curIsWriteable ) ? ` disabled` : `` ) ~ `>`;
						}
						if( curCell.type == FieldType.Bool )
						{	string nullSelStr = ( curCell.isNull() ) ? ` selected` : ``;
							string yesSelStr = ``;
							string noSelStr = ``;
							if( !curCell.isNull() )
							{	if( curCell.getBool ) yesSelStr = ` selected`;
								else noSelStr = ` selected`;
							}
							resultStr ~= `<select` ~ nameAttribStr ~ ( ( !curIsWriteable ) ? ` disabled` : `` ) ~ `>`;
							if( curCell.isNullable )
								resultStr ~= `<option value="null"` ~ nullSelStr ~ `>` ~ _nullCellDefaultStr ~ `</option>`;
								
							resultStr ~= 
							`<option value="yes"` ~ yesSelStr ~ `>` ~ _trueCellDefaultStr ~`</option>`
							`<option value="no"` ~ noSelStr ~ `>` ~ _falseCellDefaultStr ~`</option>`
							`</select>`;
						}
						break;
					}
					default:
					
					break;
				}  
				}  //with( FieldViewManner )
				resultStr ~= `</td>`;
			}
			resultStr ~= `</tr>`;
		}
		resultStr ~= `</table>`;
		return resultStr;
		
	}
}