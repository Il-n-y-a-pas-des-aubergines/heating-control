
-- drop table t_reading;

create table if not exists t_mapping(
    id INTEGER primary key autoincrement,
    address TEXT not null,
    name TEXT not null,
    valid_from INTEGER not null,
    valid_to INTEGER
);

create table if not exists t_reading(
    id INTEGER primary key autoincrement,
    mapping_id INTEGER not null,
    time INTEGER not null,
    reading INTEGER not null,
    FOREIGN KEY (mapping_id) REFERENCES t_mapping(id)
);

create table if not exists t_logging(
    id INTEGER primary key autoincrement,
    timestamp INTEGER not null,
    state TEXT not null,
    module TEXT not null,
    message TEXT not null
);
