module mkk_site.data_model.registration;

public import mkk_site.data_model.common;
import webtank.common.optional: Optional, Undefable;

struct UserRegistrationData
{
	Optional!size_t touristNum;
	Undefable!string familyName;
	Undefable!string givenName;
	Undefable!string patronymic;
	Undefable!string email;
	Undefable!string contactInfo;
	Undefable!string login;
	Undefable!string password;
}