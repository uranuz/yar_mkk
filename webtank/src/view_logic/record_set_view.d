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
	FieldViewManner[] viewManners;
	FieldOutputMode[] outputModes;
	bool[] writeableFlags;
	RecordSet recordSet;
	bool showHeader = true;
	
	string[] fieldHTMLClasses;
	string HTMLTableClass;
	//string[] nullStrings;
	//string[] trueStrings; 
	//string[] falseStrings;
	
	//alias void function(size_t key) CellHandler;
	
	//CellHandler[] handlers;
	
	string nullStrDefault = `Не задано`;
	string trueStrDefault = `Да`;
	string falseStrDefault = `Нет`;

public:
	this( RecordSet recSet )
	{	recordSet = recSet; }
	
	
	string getHTMLStr()
	{	string resultStr = `<table` ~ ( ( HTMLTableClass.length > 0 ) ? (` class="` ~ HTMLTableClass ~ `"`) : `` ) ~ `>`;
		resultStr ~= `<tr>`;
		if( showHeader )
		{	for( int k = 0; k < recordSet.fieldCount; ++k )
			{	if( ( outputModes.length <= k ) || (outputModes[k] == FieldOutputMode.none) ) //Не делаем вывод поля
					continue;
				resultStr ~= `<th>` ~ recordSet.getField(k).name ~ `</th>`; 
			}
		}
		resultStr ~= `</tr>`;
		
		//TODO: Добавить окошечки для фильтрации, если надо
		foreach( rec; recordSet )
		{	resultStr ~= `<tr>`;
			for( size_t j = 0; j <recordSet.fieldCount; ++j )
			{	if( ( outputModes.length <= j ) || (outputModes[j] == FieldOutputMode.none) ) //Не делаем вывод поля
					continue;
				auto curCell = rec[j];
				auto curViewManner = ( j < viewManners.length ) ? viewManners[j] : FieldViewManner.plainText;
				bool curIsWriteable = ( j < writeableFlags.length ) ? writeableFlags[j] : false; //По-умолчанию не записываемый
				resultStr ~= `<td`
					~ ( ( (j < fieldHTMLClasses.length) && (fieldHTMLClasses[j].length > 0) ) ? (` class="` ~ fieldHTMLClasses[j] ~ `"`) : "" ) ~ `>`;
				with( FieldViewManner ) {
				switch( curViewManner )
				{	case plainText:
					{	if( curCell.isNull() )
							resultStr ~= nullStrDefault;
						else
							resultStr ~= curCell.getStr();
						break;
					}
					case simpleControls: 
					{	string nameAttribStr = ` name="` ~ recordSet.getField(j).name ~ `_` ~ recordSet._frontKey.to!string ~ `"`;
						if( curCell.type == FieldType.Int || curCell.type == FieldType.Str || curCell.type == FieldType.IntKey )
						{	resultStr ~= `<input type="text"` ~ nameAttribStr ~ ` value="`
								~ ( ( curCell.isNull() ) ? nullStrDefault : curCell.getStr() ) ~`"` 
								~ ( ( !curIsWriteable ) ? ` disabled` : `` ) ~ `>`;
						}
						if( curCell.type == FieldType.Bool )
						{	string nullSelStr = ( curCell.isNull() ) ? ` selected` : ``;
							string yesSelStr = ``;
							string noSelStr = ``;
							if( !curCell.isNull() )
							{	if( curCell.getBool() ) yesSelStr = ` selected`;
								else noSelStr = ` selected`;
							}
							resultStr ~= `<select` ~ nameAttribStr ~ ( ( !curIsWriteable ) ? ` disabled` : `` ) ~ `>`;
							if( curCell.isNullable )
								resultStr ~= `<option value="null"` ~ nullSelStr ~ `>` ~ nullStrDefault ~ `</option>`;
								
							resultStr ~= 
							`<option value="yes"` ~ yesSelStr ~ `>` ~ trueStrDefault ~`</option>`
							`<option value="no"` ~ noSelStr ~ `>` ~ falseStrDefault ~`</option>`
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