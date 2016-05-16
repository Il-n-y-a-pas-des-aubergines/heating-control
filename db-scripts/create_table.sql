
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
    time INTEGER not null,
    mapping_id INTEGER,
    reading INTEGER,
    FOREIGN KEY (mapping_id) REFERENCES t_mapping(id)
);

create table if not exists t_logging(
    id INTEGER primary key autoincrement,
    timestamp INTEGER not null,
    moduleName TEXT not null,
    state TEXT not null,
    message TEXT not null
);
