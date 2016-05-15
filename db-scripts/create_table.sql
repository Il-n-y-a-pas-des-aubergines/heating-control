
drop table temperatur_werte;

create table if not exists temperatur_werte (
id integer primary key autoincrement,
zeitpunkt integer not null,
raum_temp real,
aussen_temp real,
puffer_1 real,
puffer_2 real,
puffer_3 real,
puffer_4 real,
boiler_1 real,
boiler_2 real,
boiler_3 real,
boiler_4 real
);

insert into temperatur_werte (zeitpunkt,raum_temp) values (47,20.5);
insert into temperatur_werte (zeitpunkt,raum_temp) values (48,21.5);