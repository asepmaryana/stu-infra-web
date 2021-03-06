alter table node drop column genset_cr;
alter table node drop column genset_cs;
alter table node drop column genset_ct;
alter table node drop column batt_curr;
alter table node drop column breaker_status;
alter table node drop column genset_fail;
alter table node drop column cdc_mode;
alter table node drop column run_hour;

alter table data_log drop column genset_cr;
alter table data_log drop column genset_cs;
alter table data_log drop column genset_ct;
alter table data_log drop column batt_curr;
alter table data_log drop column breaker_status;
alter table data_log drop column genset_fail;
alter table data_log drop column cdc_mode;
alter table data_log drop column run_hour;

alter table node add column timer_genset_on  NUMERIC;
alter table node add column timer_genset_off  NUMERIC;
alter table node add column run_hour  NUMERIC;
alter table node add column run_hour_tresh  NUMERIC;
alter table node add column genset_on_fail   SMALLINT DEFAULT 0;
alter table node add column genset_off_fail   SMALLINT DEFAULT 0;
alter table node add column sin_high_temp   SMALLINT DEFAULT 0;
alter table node add column eng_high_temp   SMALLINT DEFAULT 0;
alter table node add column oil_pressure   SMALLINT DEFAULT 0;
alter table node add column maintain_status   SMALLINT DEFAULT 0;
alter table node add column last_on  TIMESTAMP;
alter table node add column last_off TIMESTAMP;
alter table node add column next_on  TIMESTAMP;
alter table node add column next_off TIMESTAMP;
alter table node add column batt_volt_minor NUMERIC DEFAULT 47.9;
alter table node add column batt_volt_major NUMERIC DEFAULT 47.7;
alter table node add column batt_volt_critical NUMERIC DEFAULT 47.5;
alter table node add column	trap_updated TIMESTAMP;
alter table users add column popup_enabled SMALLINT NOT NULL DEFAULT 1;

alter table data_log add column timer_genset_on  NUMERIC;
alter table data_log add column timer_genset_off  NUMERIC;
alter table data_log add column run_hour  NUMERIC;
alter table data_log add column run_hour_tresh  NUMERIC;
alter table data_log add column genset_on_fail   SMALLINT DEFAULT 0;
alter table data_log add column genset_off_fail   SMALLINT DEFAULT 0;
alter table data_log add column sin_high_temp   SMALLINT DEFAULT 0;
alter table data_log add column eng_high_temp   SMALLINT DEFAULT 0;
alter table data_log add column oil_pressure   SMALLINT DEFAULT 0;
alter table data_log add column maintain_status   SMALLINT DEFAULT 0;
alter table alarm_temp add column acknowledge SMALLINT DEFAULT 0;

drop view node_view cascade;
alter table node add column opr_status_id INT DEFAULT 1;
alter table node add constraint opr_status_fk foreign key(opr_status_id) references opr_status(id) on delete set null;

alter table config add column batt_volt REAL NOT NULL DEFAULT 47;
alter table config add column comm_lost_time SMALLINT NOT NULL DEFAULT 6;
alter table config add column shift_time VARCHAR(6) NOT NULL DEFAULT '09:00';