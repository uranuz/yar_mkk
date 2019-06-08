module mkk.security.common.exception;

// Класс исключения в аутентификации
class SecurityException: Exception
{
	this(string msg, string file = __FILE__, size_t line = __LINE__) {
		super(msg, file, line);
	}
}