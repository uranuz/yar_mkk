module mkk.tools.server_runner;

import std.process, core.thread, std.file, std.stdio, std.conv, std.datetime;

import core.stdc.stdlib: exit, EXIT_FAILURE, EXIT_SUCCESS;
import core.thread: Thread, dur;
import core.sys.posix.sys.stat: umask;
import core.sys.posix.unistd: fork, setsid, chdir, close, STDIN_FILENO, STDOUT_FILENO, STDERR_FILENO;

import std.getopt;

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
	close(STDOUT_FILENO);
	close(STDERR_FILENO);
}

Pid spawnApp(string appFile)
{
	return spawnProcess( appFile, File("/dev/null"), File("/dev/null", "a"), File("/dev/null", "a") );
}

void writeLog(string logFile, string msg)
{
	if( logFile.length && exists(logFile) ) {
		std.file.append( logFile, Clock.currTime().toISOExtString() ~ `: ` ~ msg  ~ "\n\n" );
	}
}

void main(string[] args)
{
	string appFile;
	string logFile;
	int timeout = 10;
	
	getopt(args,
		`app`, &appFile, 
		`log`, &logFile,
		`timeout`, &timeout
	);

	daemonize();

	bool started = false;
	Pid childPid;
	while( true )
	{
		if( !started ) {
			try
			{
				childPid = spawnApp(appFile);
				started = true;
				writeLog( logFile, "Child process started" );
			}
			catch (Throwable e)
			{
				started = false;
				writeLog( logFile, "Exception thrown during spawn site: " ~ e.msg );
				Thread.sleep( dur!("seconds")( timeout ) );
				continue;
			}
		}

		if( started )
		{
			auto childInfo = tryWait( childPid );
			if( childInfo.terminated )
			{
				started = false;
				writeLog( logFile, "Child process terminated with code: " ~ childInfo.status.text );
				continue;
			}
		}
		
		Thread.sleep( dur!("seconds")( timeout ) );
	}
}