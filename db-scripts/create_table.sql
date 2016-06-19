
-- create tables for heating control 

-- usage:
-- $ sqlite3 ../db/measurements.db
-- sqlite> .read create_table.sql
-- sqlite> .schema

drop table t_mapping;
drop table t_reading;
drop table t_logging;

-- maps sensor ID (addrss) to it's description (name)
create table if not exists t_mapping(
    id INTEGER primary key autoincrement,
    address TEXT not null,
    name TEXT not null,
    usage_from INTEGER not null,
    usage_till INTEGER
);

-- stores the read sensor data
-- sensor usage: see mapping
create table if not exists t_reading(
    id INTEGER primary key autoincrement,
    mapping_id INTEGER not null,
    time INTEGER not null,
    reading INTEGER not null,
    FOREIGN KEY (mapping_id) REFERENCES t_mapping(id)
);

-- logging informations
create table if not exists t_logging(
    id INTEGER primary key autoincrement,
    timestamp INTEGER not null,
    state TEXT not null,
    module TEXT not null,
    message TEXT not null
);
