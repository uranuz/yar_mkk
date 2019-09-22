module mkk.tools.deploy.common;

import std.stdio: writeln;
import std.process: wait, Pid;
import std.exception: enforce;

// Выводит сообщение о текущем действии в консоль. Ждет выполнения команды по pid'у. Выводит ошибку, если она случилась
void _waitProc(Pid pid, string action)
{
	writeln(action, `...`);
	scope(exit) {
		enforce(wait(pid) == 0, `Ошибка операции: ` ~ action);
	}
}