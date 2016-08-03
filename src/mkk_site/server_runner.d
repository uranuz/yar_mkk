import std.process, core.thread, std.file, std.stdio, std.conv, std.datetime;

import core.stdc.stdlib : exit, EXIT_FAILURE, EXIT_SUCCESS;
import core.thread : Thread, dur;
import core.sys.posix.sys.stat : umask;
import core.sys.posix.unistd : fork, setsid, chdir, close, STDIN_FILENO, STDOUT_FILENO, STDERR_FILENO;

extern (C)
{
	void _Exit(int);
}

void daemonize()
{
	// fork this process
	auto pid = fork();
	if (pid == -1) exit(EXIT_FAILURE);

	// this is the parent; terminate it
	if (pid > 0)
	{
		writefln("Starting daemon mode, process id = %d\n", pid);
		_Exit(EXIT_SUCCESS);
	}
	//unmask the file mode
	umask(0);

	// become process group leader
	auto sid = setsid();
	if(sid < 0) exit(EXIT_FAILURE);

	// do not lock any directories
	//chdir("/");

	// Close stdin, stdout and stderr
	close(STDIN_FILENO);
	//	close(STDOUT_FILENO);
	//	close(STDERR_FILENO);
}


static immutable logFileName = "./server_runner.log";

Pid spawnSite()
{
	return spawnProcess( "./mkk_site_release", File("/dev/null"), File("./server_output.txt", "a"), File("./server_errors.txt", "a") );
}

void main()
{
	daemonize();

	Pid childPid = spawnSite();
	while( true )
	{
		auto childInfo = tryWait( childPid );
		if( childInfo.terminated )
		{
			auto currentTime = Clock.currTime();
			std.file.append( logFileName, currentTime.toISOExtString() ~ ": Child process terminated with code: " ~ childInfo.status.text ~ "\n\n" );
			Thread.sleep( dur!("seconds")( 3 ) );
			try {
				childPid = spawnSite();
			}
			catch (Throwable e)
			{
				currentTime = Clock.currTime();
				std.file.append( logFileName, currentTime.toISOExtString() ~ ": Exception thrown during spawn site: " ~ e.msg ~ "\n\n" );
			}
		}
		Thread.sleep( dur!("seconds")( 5 ) );
	}
}