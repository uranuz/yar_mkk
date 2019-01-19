module mkk_site.main_service.pohod.file_links.edit;

import mkk_site.main_service.devkit;

import mkk_site.data_model.pohod_edit: PohodFileLink;

void writePohodFileLinks(Undefable!(PohodFileLink[]) fileLinks, size_t pohodNum)
{
	import std.algorithm: map;
	import std.array: join;
	import std.conv: text;
	import std.string: strip;

	if( fileLinks.isUndef )
		return;
	string[] insertFileLinks;
	string[] updateFileLinks;
	size_t[] updateKeys;

	
	foreach( ref item; fileLinks )
	{
		string uriStr = strip(item.link);
		if( !uriStr.length )
			continue;

		URI uri;
		try {
			uri = URI(uriStr);
		} catch(Exception ex) {
			throw new Exception("Некорректная ссылка на доп. материалы!!!");
		}

		if( uri.scheme.length == 0 )
			uri.scheme = "http";

		if( item.num.isSet ) {
			updateKeys ~= item.num.value;
			updateFileLinks ~= `(` ~ item.num.text ~ `, '` ~ PGEscapeStr(item.name) ~ `', '` ~ PGEscapeStr(item.link) ~ `', ` ~ pohodNum.text ~ `)`;
		} else {
			insertFileLinks ~= `('` ~ PGEscapeStr(item.name) ~ `', '` ~ PGEscapeStr(item.link) ~ `', ` ~ pohodNum.text ~ `  )`;
		}
	}

	// Удаляем ссылки на файлы похода, которых нет в списке
	getCommonDB().query(`with upd_keys as(
		select unnest(ARRAY[` ~ updateKeys.map!( (it) => it.text ).join(`,`) ~ `]::integer[]) num
	)
	delete from pohod_file_link
	where pohod_num = ` ~ pohodNum.text ~ `
		and num not in(select num from upd_keys)
	`);

	// Обновляем существующие ссылки
	if( updateFileLinks.length ) {
		getCommonDB().query(`with dat(num, name, link, pohod_num) as(
			values
			` ~ updateFileLinks.join(",\n") ~ `
		)
		update pohod_file_link
		set
			name = dat.name,
			link = dat.link,
			pohod_num = dat.pohod_num
		from dat
		where dat.num = pohod_file_link.num
		`);
	}

	// Вставляем новые записи
	if( insertFileLinks.length ) {
		getCommonDB().query(`with dat(name, link, pohod_num) as(
			values
			` ~ insertFileLinks.join(",\n") ~ `
		)
		insert into pohod_file_link (name, link, pohod_num)
		select * from dat
		`);
	}
}