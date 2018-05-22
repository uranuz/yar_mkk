 
with raw_rows as(
	select
	num,
	unnest(links) raw_link
	from pohod
	where links is not null and array_length(links, 1) > 0
),
parsed_links as(
select
	num "pohod_num",
	split_part(raw_link, '><', 2) "name",
	split_part(raw_link, '><', 1) "link"
from raw_rows
where length(raw_link) > 0
)
insert into pohod_file_link ("pohod_num", "name", "link") select * from parsed_links
