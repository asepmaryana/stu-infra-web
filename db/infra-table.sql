CREATE TABLE role
(
    id SERIAL NOT NULL,
    name VARCHAR(20),
    PRIMARY KEY(id),
    UNIQUE(name)
);

INSERT INTO role(name) VALUES 
('SYSTEM'), ('ADMIN'), ('OPERATOR');

CREATE TABLE users
(
    id SERIAL NOT NULL,
    username VARCHAR(30),
    password VARCHAR(100),
    name VARCHAR(100),
    role_id INT,
	popup_enabled SMALLINT NOT NULL DEFAULT 1,
    PRIMARY KEY(id),
    UNIQUE(username),
    FOREIGN KEY(role_id) REFERENCES role(id) ON DELETE SET NULL
);

INSERT INTO users(username, password, name, role_id) VALUES 
('sa', md5('sysadmin'), 'System', 1),
('admin', md5('admin'), 'Administrator', 2),
('user', md5('user'), 'Operator', 3);



CREATE TABLE severity
(
    id SERIAL NOT NULL,
    name VARCHAR(10),
    color VARCHAR(7),
    PRIMARY KEY(id),
    UNIQUE(name)
);

INSERT INTO severity (name, color) VALUES 
('CRITICAL', '#FF0000'),
('MAJOR', '#00FF00'),
('MINOR', '#FF0000'),
('WARNING', '#FF0000');

CREATE TABLE alarm_list
(
    id SERIAL NOT NULL,
    name VARCHAR(50) NOT NULL,
    severity_id INT,
    PRIMARY KEY(id),
    UNIQUE(name),
    FOREIGN KEY(severity_id) REFERENCES severity(id) ON DELETE SET NULL    
);

INSERT INTO alarm_list (name, severity_id) VALUES 
('Genset ON Fail', 1),
('Genset OFF Fail', 1),
('Low Fuel', 2),
('Rectifier Fail', 1),
('Low Battery', 2),
('Sinegen High Temp', 2),
('Engine High Temp', 2),
('Oil Pressure', 3),
('Maintenance', 4);

CREATE TABLE customer
(
    id SERIAL NOT NULL,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(100),
    PRIMARY KEY(id),
    UNIQUE(name)
);

CREATE TABLE opr_status
(
    id INT NOT NULL,
    name VARCHAR(20) NOT NULL,
    PRIMARY KEY(id),
    UNIQUE(name)
);

INSERT INTO opr_status(id, name) VALUES 
(1, 'Operational'),
(2, 'Maintenance'),
(3, 'Comm Lost');

INSERT INTO customer (name) VALUES 
('PT. Telkom Infra'),
('PT. XL Axiata');

CREATE TABLE subnet
(
    id SERIAL NOT NULL,
    name VARCHAR(50) NOT NULL,
    parent_id INT,
    customer_id INT,
    PRIMARY KEY(id),
    FOREIGN KEY(parent_id) REFERENCES subnet(id) ON DELETE CASCADE,
    FOREIGN KEY(customer_id) REFERENCES customer(id) ON DELETE SET NULL
);

INSERT INTO subnet (name, parent_id, customer_id) VALUES 
('Jawa Barat', NULL, 1),
('Bandung', 1, 1),
('Buah Batu', 2, 1);

CREATE TABLE node
(
    id SERIAL NOT NULL,
    phone VARCHAR(10) NOT NULL,
    name VARCHAR(50),
    subnet_id INT,
    customer_id INT,
    opr_status_id INT,
    latitude NUMERIC,
	longitude NUMERIC,
    genset_vr NUMERIC,
    genset_vs NUMERIC,
    genset_vt NUMERIC,
    batt_volt NUMERIC,
	batt_volt_minor NUMERIC DEFAULT 47.9,
	batt_volt_major NUMERIC DEFAULT 47.7,
	batt_volt_critical NUMERIC DEFAULT 47.5,
    genset_batt_volt NUMERIC,
    timer_genset_on  INT,
    timer_genset_off INT,
    run_hour         INT,
    run_hour_tresh   INT,
    genset_status 	 SMALLINT DEFAULT 0,    
    genset_on_fail   SMALLINT DEFAULT 0,
    genset_off_fail  SMALLINT DEFAULT 0,
    low_fuel   		 SMALLINT DEFAULT 0,
    recti_fail       SMALLINT DEFAULT 0,
    batt_low      	 SMALLINT DEFAULT 0,
    sin_high_temp    SMALLINT DEFAULT 0,
    eng_high_temp    SMALLINT DEFAULT 0,
    oil_pressure     SMALLINT DEFAULT 0,
    maintain_status  SMALLINT DEFAULT 0,
    recti_status 	 SMALLINT DEFAULT 0,
    next_on     	TIMESTAMP,
    next_off    	TIMESTAMP,
    created_at  	TIMESTAMP,
    updated_at  	TIMESTAMP,
	trap_updated  	TIMESTAMP,
    PRIMARY KEY(id),
    UNIQUE(phone),
    FOREIGN KEY(subnet_id) REFERENCES subnet(id) ON DELETE CASCADE,
    FOREIGN KEY(customer_id) REFERENCES customer(id) ON DELETE SET NULL,
    FOREIGN KEY(opr_status_id) REFERENCES opr_status(id) ON DELETE SET NULL
);

INSERT INTO node (phone,name,subnet_id,customer_id, created_at) VALUES 
('087825411059', 'Test', 3, 1, now());

CREATE TABLE data_log
(
    id BIGSERIAL NOT NULL,
    node_id INT NOT NULL,
    dtime TIMESTAMP NOT NULL,
    genset_vr NUMERIC,
    genset_vs NUMERIC,
    genset_vt NUMERIC,
    batt_volt NUMERIC,
    genset_batt_volt NUMERIC,
    timer_genset_on  INT,
    timer_genset_off INT,
    run_hour         INT,
    run_hour_tresh   INT,
    genset_status 	 SMALLINT DEFAULT 0,    
    genset_on_fail   SMALLINT DEFAULT 0,
    genset_off_fail  SMALLINT DEFAULT 0,
    low_fuel   		 SMALLINT DEFAULT 0,
    recti_fail       SMALLINT DEFAULT 0,
    batt_low      	 SMALLINT DEFAULT 0,
    sin_high_temp    SMALLINT DEFAULT 0,
    eng_high_temp    SMALLINT DEFAULT 0,
    oil_pressure     SMALLINT DEFAULT 0,
    maintain_status  SMALLINT DEFAULT 0,
    recti_status 	 SMALLINT DEFAULT 0,
    PRIMARY KEY(id),
    UNIQUE(node_id, dtime),
    FOREIGN KEY(node_id) REFERENCES node(id) ON DELETE CASCADE
);

CREATE TABLE alarm_temp
(
    id BIGSERIAL NOT NULL,    
    node_id INT NOT NULL,
    dtime TIMESTAMP NOT NULL,
    alarm_list_id INT NOT NULL,
    alarm_label VARCHAR(50),
    severity_id INT,
    PRIMARY KEY(id),
    FOREIGN KEY(node_id) REFERENCES node(id) ON DELETE CASCADE,
    FOREIGN KEY(alarm_list_id) REFERENCES alarm_list(id) ON DELETE SET NULL,
    FOREIGN KEY(severity_id) REFERENCES severity(id) ON DELETE SET NULL
);

CREATE TABLE alarm_log
(
    id BIGINT NOT NULL,    
    node_id INT NOT NULL,
    dtime TIMESTAMP NOT NULL,
    dtime_end TIMESTAMP,
    alarm_list_id INT NOT NULL,
    alarm_label VARCHAR(50),
    severity_id INT,
    PRIMARY KEY(id),
    FOREIGN KEY(node_id) REFERENCES node(id) ON DELETE CASCADE,
    FOREIGN KEY(alarm_list_id) REFERENCES alarm_list(id) ON DELETE SET NULL,
    FOREIGN KEY(severity_id) REFERENCES severity(id) ON DELETE SET NULL
);

CREATE TABLE running_hour
(
    id BIGSERIAL NOT NULL,    
    node_id INT NOT NULL,
    ddate DATE NOT NULL,
    val REAL NOT NULL DEFAULT 0,
    PRIMARY KEY(id),
    FOREIGN KEY(node_id) REFERENCES node(id) ON DELETE CASCADE
);

CREATE INDEX run_hour_date_idx ON running_hour(ddate);
CREATE INDEX run_hour_node_idx ON running_hour(node_id);

CREATE TABLE command
(
    id SERIAL NOT NULL,
    name VARCHAR(100) NOT NULL,
    val VARCHAR(50) NOT NULL,
    PRIMARY KEY(id),
    UNIQUE(val)
);

INSERT INTO command (name, val) VALUES('ON GENSET MANUAL', '#SET#0000#GENSET#ON#');
INSERT INTO command (name, val) VALUES('OFF GENSET MANUAL', '#SET#0000#GENSET#OFF#');
INSERT INTO command (name, val) VALUES('SETTING LOW VOLTAGE UNTUK REFERENSI GENSET ON', '#SET#0000#LOWVOLT#47.5#');
INSERT INTO command (name, val) VALUES('SETTING NO SERVER REPORT SMS', '#SET#0000#SV1#08123456789#');
INSERT INTO command (name, val) VALUES('SETTING NO OPERATOR.1 REPORT SMS', '#SET#0000#OP1#08123456789#');
INSERT INTO command (name, val) VALUES('SETTING NO OPERATOR.2 REPORT SMS', '#SET#0000#OP2#08123456789#');
INSERT INTO command (name, val) VALUES('SETTING NO OPERATOR.3 REPORT SMS', '#SET#0000#OP3#08123456789#');
INSERT INTO command (name, val) VALUES('SETTING NO OPERATOR.4 REPORT SMS', '#SET#0000#OP4#08123456789#');
INSERT INTO command (name, val) VALUES('SETTING NO OPERATOR.5 REPORT SMS', '#SET#0000#OP5#08123456789#');
INSERT INTO command (name, val) VALUES('SETTING PERIODIC REPORT SMS', '#SET#0000#PER#15#');
INSERT INTO command (name, val) VALUES('SETTING PERIODIC ALARM REPORT SMS', '#SET#0000#PERALM#15#');
INSERT INTO command (name, val) VALUES('SETTING TIMER WARMING UP', '#SET#0000#TWU#2#');
INSERT INTO command (name, val) VALUES('SETTING TIMER COOLING DOWN', '#SET#0000#TCD#2#');
INSERT INTO command (name, val) VALUES('SETTING /GANTI PASSWORD', '#SET#0000#PWD#4567#');
INSERT INTO command (name, val) VALUES('RESET RUNING HOUR GENSET', '#SET#0000#RUNHOUR#RESET#');
INSERT INTO command (name, val) VALUES('SETTING/KALIBRASI NILAI RUNING HOUR', '#SET#0000#RUNHOUR#700#');
INSERT INTO command (name, val) VALUES('SETTING SITE NAME', '#SET#0000#SITE#XXXXXXXXXX#');
INSERT INTO command (name, val) VALUES('SETTING SITE ID', '#SET#0000#ID#XXXXXXXXXX#');
INSERT INTO command (name, val) VALUES('SETTING/KALIBRASI PEMBACAAN TEGANGAN AC', '#SET#0000#OAC#220.0#');
INSERT INTO command (name, val) VALUES('SETTING/KALIBRASI PEMBACAAN TEGANGAN BATT ', '#SET#0000#OBT#48.0#');
INSERT INTO command (name, val) VALUES('SETTING/KALIBRASI PEMBACAAN TEGANGAN ACCU', '#SET#0000#OAQ#12.0#');
INSERT INTO command (name, val) VALUES('GET DATA PEMBACAAN SYSTEM', '#GET#0000#MOD#0#');
INSERT INTO command (name, val) VALUES('GET DATA ALARM', '#GET#0000#ALM#0#');
INSERT INTO command (name, val) VALUES('GET NO SERVER REPORT SMS', '#GET#0000#SVR#0#');
INSERT INTO command (name, val) VALUES('GET NO OPERATOR REPORT SMS', '#GET#0000#OPR#0#');
INSERT INTO command (name, val) VALUES('GET NILAI SETTING PARAMETER', '#GET#0000#VALUE#0#');
INSERT INTO command (name, val) VALUES('GET/CHECK PULSA', '#GET#0000#PLS#0#');

CREATE TABLE config
(
    id VARCHAR(255) NOT NULL,
    server_port INT NOT NULL DEFAULT 9876,
    cron_scheduler VARCHAR(50) NOT NULL DEFAULT '0 */5 * * * *',
    alarm_tolerance INT NOT NULL DEFAULT 30,
    node_limit INT NOT NULL DEFAULT 100,
    sms_limit INT NOT NULL DEFAULT 50,
	batt_volt REAL NOT NULL DEFAULT 47,
	comm_lost_time SMALLINT NOT NULL DEFAULT 6,
    PRIMARY KEY(id)
);

INSERT INTO config(id) VALUES ('1');


CREATE TABLE operator
(
    id SERIAL NOT NULL,
    name VARCHAR(100) NOT NULL,
	phone VARCHAR(20) NOT NULL,
	mon SMALLINT NOT NULL DEFAULT 0,
	tue SMALLINT NOT NULL DEFAULT 0,
	wed SMALLINT NOT NULL DEFAULT 0,
	thu SMALLINT NOT NULL DEFAULT 0,
	fri SMALLINT NOT NULL DEFAULT 0,
	sat SMALLINT NOT NULL DEFAULT 0,
	sun SMALLINT NOT NULL DEFAULT 0,
	enabled SMALLINT NOT NULL DEFAULT 1,
    PRIMARY KEY(id),
	UNIQUE(phone)
);