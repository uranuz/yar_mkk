module webtank.net.routing;

import std.stdio;
import webtank.common.utils, webtank.net.connection;

///Модуль содержит основные интерфейсы для маршрутизации
///запросов веб-приложения на основе библиотеки webtank

//Класс исключения при маршрутизации
class RoutingException : Exception {
	this(string msg, string file = __FILE__, size_t line = __LINE__) {
		super(msg, file, line);
	}
}

enum RoutingStatus {	continued, succeed, failed };

///Статический класс внутрипрограммного маршрутизатора
abstract class Router
{
	static {
		///Присоединяет правило маршрутизации к системе
		Router join(IRoutingRule routingRule)
		{	_routingRules ~= routingRule;
			return null;
		}
		
		///Присоединяет массив правил маршрутизации к системе
		Router join(IRoutingRule[] routingRules)
		{	_routingRules ~= routingRules.dup;
			return null;
		}
		
		///Запускает маршрутизацию для заданного контекста подключения
		void process(IConnectionContext context)
		{	auto status = _rootRule.doRouting(context);
		}
		
		//Внутренняя функция для построения дерева маршрутизации
		protected void _buildRoutingTree()
		{	
			import std.algorithm;
			sort!(`count(a.routeName, "` ~ routeNamePartsDelim 
				~ `") < count(b.routeName, "` ~ routeNamePartsDelim ~ `")`)(_routingRules);
			
			if( _routingRules.length == 0 )
				return;
				
			//Определяем корневое правило из списка добавленных правил
			if( _routingRules.length > 1 )
			{	auto firstDelimCount = count(_routingRules[0].routeName, routeNamePartsDelim);
				auto secondDelimCount = count(_routingRules[1].routeName, routeNamePartsDelim);
			
				if ( firstDelimCount == secondDelimCount )
					throw new RoutingException("Can't determine root routing rule!!!");
				else
					_rootRule = _routingRules[0];
			}
			else if( _routingRules.length == 1 )
				_rootRule = _routingRules[0];
			
			foreach( rule; _routingRules[1..$])
				_rootRule.joinRule(rule);
				
		}
		
		///Инициализация маршрутизатора
		void start()
		{	if( _rootRule is null )
				_buildRoutingTree();
		}
		
	} //static
protected:
	static {
		__gshared IRoutingRule _rootRule;
		__gshared IRoutingRule[] _routingRules;
	} //static
}



//Интерфейс набора правил маршрутизации
interface IRoutingRuleSet
{	IRoutingRule[] getRoutingRules();
}

//Интерфейс правила маршрутизации
interface IRoutingRule
{	//Имена маршрутов, в которых применяется правило
	//Для одного правила нельзя (и вроде бы бессмысленно) задавать 
	//несколько имён на одном уровнее в одном "домене"
	string routeName() @property;
	
	//Присоединяем правило маршрутизации
	void joinRule(IRoutingRule newRule);
	
	//Метод получения участка маршрута
	//routeName - имя маршрута, для которого создаётся участок
	//context - "полезная нагрузка", передаваемая по маршруту
	RoutingStatus doRouting(IConnectionContext context);
	
	//Метод для просмотра дочерних правил данного правила (не рекурсивно)
	int opApply(int delegate(IRoutingRule) dg);
	
	//Набор правил маршрутизации, из которого получено данное правило
	IRoutingRuleSet ruleSet() @property;
	
	//Вывод информации о дереве маршрутизации
	final string toString()
	{	string result = routeName ~ "\r\n";
		foreach( childRule; &this.opApply )
			result ~= childRule.toString();
		return result;
	}
}



//Разделитель в имени маршрута
immutable routeNamePartsDelim = ".";

class ForwardRoutingRule(ChildRuleT = IRoutingRule): IRoutingRule
//  	if( is( ChildRuleT : IRoutingRule ) )
{	
protected:
	immutable(string) _routeName;
	
public:

	this(string thisRouteName) 
	{	_routeName = thisRouteName;
	}
	
	override {
		//Имя маршрута
		string routeName()
		{	return _routeName;
		}
		
		void joinRule(IRoutingRule newRule)
		{	import std.algorithm;
			import webtank.common.utils;
			auto thisRouteNameParts = splitArray(_routeName, routeNamePartsDelim);
			auto newRouteNameParts = splitArray(newRule.routeName, routeNamePartsDelim);
			writeln("newRule.routeName: ",newRule.routeName);
			writeln("thisRouteNameParts: ", thisRouteNameParts);
			writeln("newRouteNameParts: ", newRouteNameParts);
			
			if( newRouteNameParts.startsWith(thisRouteNameParts) )
			{	auto newRelRouteNameParts = newRouteNameParts[thisRouteNameParts.length .. $];
				writeln("newRelRouteNameParts: ", newRelRouteNameParts, "\r\n");
				if( newRelRouteNameParts.length == 1 )
				{	auto newChildRule = cast( ChildRuleT ) newRule;
					if( newChildRule )
						joinToThis(newChildRule);
					else
						throw new RoutingException("New rule doesn't match child rule type or is just null!!!");
				}
				else if( newRelRouteNameParts.length > 1 )
				{	foreach( childRule; this )
					{	auto childRouteNameParts = splitArray(childRule.routeName, routeNamePartsDelim);
						writeln("childRouteNameParts: ", childRouteNameParts, "\r\n");
						if( newRouteNameParts.startsWith(childRouteNameParts) )
						{	childRule.joinRule(newRule);
							return;
						}
					}
					throw new RoutingException("No child rule found to join new rule!!!");
				}
				else
					throw new RoutingException("Incorrect rule name!!!");
			}
			else
				throw new RoutingException("Parent routing rule for new rule is not presented in the system!!!");
		}
		
		abstract RoutingStatus doRouting(IConnectionContext context);
		abstract int opApply(int delegate(IRoutingRule) dg);
		
		//По-умолчанию считаем, что набора правил нет
		//Если есть, то нужно переопределить
		IRoutingRuleSet ruleSet()
		{	return null;
		}
	} //override
	
	//Метод присоединения правила к этому правилу
	abstract void joinToThis(ChildRuleT newRule);
}

class EndPointRoutingRule: IRoutingRule
{	
protected:
	string _routeName;
	
public:
	this(string thisRouteName) 
	{	_routeName = thisRouteName;
	}
	
	override {
		//Имя маршрута
		string routeName()
		{	return _routeName; }
		
		void joinRule(IRoutingRule newRule)
		{	throw new RoutingException("Can't join new rule to end-point rule!!!");
		}
		
		abstract RoutingStatus doRouting(IConnectionContext context);
		
		int opApply(int delegate(IRoutingRule) dg)
		{	return 0; }
		
		//По-умолчанию считаем, что набора правил нет
		//Если есть, то нужно переопределить
		IRoutingRuleSet ruleSet()
		{	return null; 	}
	} //override
}
