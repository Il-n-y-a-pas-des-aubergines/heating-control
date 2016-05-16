
drop table t_readings;

create table if not exists t_mapping(
	id INTEGER primary key autoincrement,
	address TEXT not null,
	name TEXT not null,
	valid_from INTEGER not null,
	valid_to INTEGER
);

create table if not exists t_reading(
	id INTEGER primary key autoincrement,
	time INTEGER not null,
	mapping_id INTEGER foreign key references t_mapping(id),
	reading INTEGER
);
