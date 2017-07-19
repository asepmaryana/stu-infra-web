-- Node Update Trigger Handler
CREATE OR REPLACE FUNCTION trg_node_update() 
    RETURNS TRIGGER AS $$
    DECLARE 
        
        -- Trigger data log
        -- 
        -- Author : Asep Maryana
        -- Email  : asep.maryana@gmail.com
        -- Website: www.asepmaryana.net
        -- Created: 27 Apr 2017 10:40 WIB
        
		_alarm_temp_id		BIGINT;
        _alarm_list_id      INT;
        _alarm_name         VARCHAR(50);
        _alarm_severity_id  INT;        
        _alarm_time			TIMESTAMP;
		_alarm_tolerance    INT;
        
    BEGIN
        
        -- read config
        SELECT alarm_tolerance INTO _alarm_tolerance FROM config WHERE id = '1';
        
        IF _alarm_tolerance IS NULL THEN
            _alarm_tolerance := 120;
        END IF;
        
        _alarm_time	:= new.updated_at;
		
        IF _alarm_time IS NULL THEN
            _alarm_time := now();
        END IF;
        
        IF new.updated_at <> old.updated_at AND new.updated_at IS NOT NULL THEN 
            
			_alarm_time	:= new.updated_at;            
            INSERT INTO data_log (node_id,dtime,genset_vr,genset_vs,genset_vt,batt_volt,genset_batt_volt,timer_genset_on,timer_genset_off,run_hour,run_hour_tresh,genset_status,genset_on_fail,genset_off_fail,low_fuel,recti_fail,batt_low,sin_high_temp,eng_high_temp,oil_pressure,maintain_status,recti_status) 
            VALUES (new.id,new.updated_at,new.genset_vr,new.genset_vs,new.genset_vt,new.batt_volt,new.genset_batt_volt,new.timer_genset_on,new.timer_genset_off,new.run_hour,new.run_hour_tresh,new.genset_status,new.genset_on_fail,new.genset_off_fail,new.low_fuel,new.recti_fail,new.batt_low,new.sin_high_temp,new.eng_high_temp,new.oil_pressure,new.maintain_status,new.recti_status);
                        
        END IF;
        
        IF new.genset_status = 1 THEN
            -- genset off ke on
            new.last_off     := old.updated_at;
            new.next_off     := new.updated_at + make_interval(mins => (new.timer_genset_on + _alarm_tolerance));
        ELSE
            -- genset on ke off
            new.last_on     := old.updated_at;
            new.next_on     := new.updated_at + make_interval(mins => (new.timer_genset_off + _alarm_tolerance));
        END IF;
        
		_alarm_temp_id := NULL;
		
		IF new.genset_on_fail <> old.genset_on_fail THEN
            
            _alarm_list_id  := 1;
			
            SELECT name,severity_id INTO _alarm_name,_alarm_severity_id FROM alarm_list WHERE id = _alarm_list_id;
            
			SELECT id INTO _alarm_temp_id FROM alarm_temp WHERE node_id = new.id AND alarm_list_id = _alarm_list_id;
			
            IF new.genset_on_fail = 1 THEN
				IF _alarm_temp_id IS NULL THEN 
					INSERT INTO alarm_temp (node_id,dtime,alarm_list_id,alarm_label,severity_id) 
					VALUES (new.id,_alarm_time,_alarm_list_id,_alarm_name,_alarm_severity_id);
				END IF;
            ELSE
                UPDATE alarm_log SET dtime_end = _alarm_time WHERE id = _alarm_temp_id;
                DELETE FROM alarm_temp WHERE node_id = new.id AND alarm_list_id = _alarm_list_id;
            END IF;
            
        END IF;
		
		IF new.genset_off_fail <> old.genset_off_fail THEN
            
            _alarm_list_id  := 2;
			
            SELECT name,severity_id INTO _alarm_name,_alarm_severity_id FROM alarm_list WHERE id = _alarm_list_id;
            
			SELECT id INTO _alarm_temp_id FROM alarm_temp WHERE node_id = new.id AND alarm_list_id = _alarm_list_id;
			
            IF new.genset_off_fail = 1 THEN
				IF _alarm_temp_id IS NULL THEN 
					INSERT INTO alarm_temp (node_id,dtime,alarm_list_id,alarm_label,severity_id) 
					VALUES (new.id,_alarm_time,_alarm_list_id,_alarm_name,_alarm_severity_id);
				END IF;
            ELSE
                UPDATE alarm_log SET dtime_end = _alarm_time WHERE id = _alarm_temp_id;
                DELETE FROM alarm_temp WHERE node_id = new.id AND alarm_list_id = _alarm_list_id;
            END IF;
            
        END IF;
		
		IF new.low_fuel <> old.low_fuel THEN
            
            _alarm_list_id  := 3;
			
            SELECT name,severity_id INTO _alarm_name,_alarm_severity_id FROM alarm_list WHERE id = _alarm_list_id;
            
			SELECT id INTO _alarm_temp_id FROM alarm_temp WHERE node_id = new.id AND alarm_list_id = _alarm_list_id;
			
            IF new.low_fuel = 1 THEN
				IF _alarm_temp_id IS NULL THEN 
					INSERT INTO alarm_temp (node_id,dtime,alarm_list_id,alarm_label,severity_id) 
					VALUES (new.id,_alarm_time,_alarm_list_id,_alarm_name,_alarm_severity_id);
				END IF;
            ELSE
                UPDATE alarm_log SET dtime_end = _alarm_time WHERE id = _alarm_temp_id;
                DELETE FROM alarm_temp WHERE node_id = new.id AND alarm_list_id = _alarm_list_id;
            END IF;
            
        END IF;
		
        IF new.recti_fail <> old.recti_fail THEN
            
            _alarm_list_id  := 4;
			
            SELECT name,severity_id INTO _alarm_name,_alarm_severity_id FROM alarm_list WHERE id = _alarm_list_id;
            
			SELECT id INTO _alarm_temp_id FROM alarm_temp WHERE node_id = new.id AND alarm_list_id = _alarm_list_id;
			
            IF new.recti_fail = 1 THEN
				IF _alarm_temp_id IS NULL THEN 
					INSERT INTO alarm_temp (node_id,dtime,alarm_list_id,alarm_label,severity_id) 
					VALUES (new.id,_alarm_time,_alarm_list_id,_alarm_name,_alarm_severity_id);
				END IF;
            ELSE
                UPDATE alarm_log SET dtime_end = _alarm_time WHERE id = _alarm_temp_id;
                DELETE FROM alarm_temp WHERE node_id = new.id AND alarm_list_id = _alarm_list_id;
            END IF;
            
        END IF;
		
        IF new.batt_low <> old.batt_low THEN
            
            _alarm_list_id  := 5;
			
            SELECT name,severity_id INTO _alarm_name,_alarm_severity_id FROM alarm_list WHERE id = _alarm_list_id;
            
			SELECT id INTO _alarm_temp_id FROM alarm_temp WHERE node_id = new.id AND alarm_list_id = _alarm_list_id;
			
            IF new.batt_low = 1 THEN
				IF _alarm_temp_id IS NULL THEN 
					INSERT INTO alarm_temp (node_id,dtime,alarm_list_id,alarm_label,severity_id) 
					VALUES (new.id,_alarm_time,_alarm_list_id,_alarm_name,_alarm_severity_id);
				END IF;
            ELSE
                UPDATE alarm_log SET dtime_end = _alarm_time WHERE id = _alarm_temp_id;
                DELETE FROM alarm_temp WHERE node_id = new.id AND alarm_list_id = _alarm_list_id;
            END IF;
            
        END IF;
        
		IF new.sin_high_temp <> old.sin_high_temp THEN
            
            _alarm_list_id  := 6;
			
            SELECT name,severity_id INTO _alarm_name,_alarm_severity_id FROM alarm_list WHERE id = _alarm_list_id;
            
			SELECT id INTO _alarm_temp_id FROM alarm_temp WHERE node_id = new.id AND alarm_list_id = _alarm_list_id;
			
            IF new.sin_high_temp = 1 THEN
				IF _alarm_temp_id IS NULL THEN 
					INSERT INTO alarm_temp (node_id,dtime,alarm_list_id,alarm_label,severity_id) 
					VALUES (new.id,_alarm_time,_alarm_list_id,_alarm_name,_alarm_severity_id);
				END IF;
            ELSE
                UPDATE alarm_log SET dtime_end = _alarm_time WHERE id = _alarm_temp_id;
                DELETE FROM alarm_temp WHERE node_id = new.id AND alarm_list_id = _alarm_list_id;
            END IF;
            
        END IF;
		
        IF new.eng_high_temp <> old.eng_high_temp THEN
            
            _alarm_list_id  := 7;
			
            SELECT name,severity_id INTO _alarm_name,_alarm_severity_id FROM alarm_list WHERE id = _alarm_list_id;
            
			SELECT id INTO _alarm_temp_id FROM alarm_temp WHERE node_id = new.id AND alarm_list_id = _alarm_list_id;
			
            IF new.eng_high_temp = 1 THEN
				IF _alarm_temp_id IS NULL THEN 
					INSERT INTO alarm_temp (node_id,dtime,alarm_list_id,alarm_label,severity_id) 
					VALUES (new.id,_alarm_time,_alarm_list_id,_alarm_name,_alarm_severity_id);
				END IF;
            ELSE
                UPDATE alarm_log SET dtime_end = _alarm_time WHERE id=_alarm_temp_id;
                DELETE FROM alarm_temp WHERE node_id = new.id AND alarm_list_id = _alarm_list_id;
            END IF;
            
        END IF;
		
        IF new.oil_pressure <> old.oil_pressure THEN
            
            _alarm_list_id  := 8;
			
            SELECT name,severity_id INTO _alarm_name,_alarm_severity_id FROM alarm_list WHERE id = _alarm_list_id;
            
			SELECT id INTO _alarm_temp_id FROM alarm_temp WHERE node_id = new.id AND alarm_list_id = _alarm_list_id;
			
            IF new.oil_pressure = 1 THEN
				IF _alarm_temp_id IS NULL THEN 
					INSERT INTO alarm_temp (node_id,dtime,alarm_list_id,alarm_label,severity_id) 
					VALUES (new.id,_alarm_time,_alarm_list_id,_alarm_name,_alarm_severity_id);
				END IF;
            ELSE
                UPDATE alarm_log SET dtime_end = _alarm_time WHERE id=_alarm_temp_id;
                DELETE FROM alarm_temp WHERE node_id = new.id AND alarm_list_id = _alarm_list_id;
            END IF;
            
        END IF;		        
        
		IF new.batt_volt <= new.batt_volt_critical THEN
            
            _alarm_list_id  := 5;
			_alarm_severity_id := 1;
			
            SELECT name INTO _alarm_name FROM alarm_list WHERE id = _alarm_list_id;
			SELECT id INTO _alarm_temp_id FROM alarm_temp WHERE node_id = new.id AND alarm_list_id = _alarm_list_id;
			
            IF _alarm_temp_id IS NULL THEN 
				INSERT INTO alarm_temp (node_id,dtime,alarm_list_id,alarm_label,severity_id) 
				VALUES (new.id,_alarm_time,_alarm_list_id,_alarm_name,_alarm_severity_id);
            END IF;
			
		ELSIF new.batt_volt <= new.batt_volt_major THEN
			
			_alarm_list_id  := 5;
			_alarm_severity_id := 2;
			
            SELECT name INTO _alarm_name FROM alarm_list WHERE id = _alarm_list_id;
			SELECT id INTO _alarm_temp_id FROM alarm_temp WHERE node_id = new.id AND alarm_list_id = _alarm_list_id;
			
            IF _alarm_temp_id IS NULL THEN 
				INSERT INTO alarm_temp (node_id,dtime,alarm_list_id,alarm_label,severity_id) 
				VALUES (new.id,_alarm_time,_alarm_list_id,_alarm_name,_alarm_severity_id);
			ELSE
				UPDATE alarm_temp SET severity_id = _alarm_severity_id WHERE id = _alarm_temp_id;
            END IF;
		
		ELSIF new.batt_volt <= new.batt_volt_minor THEN
			
			_alarm_list_id  := 5;
			_alarm_severity_id := 2;
			
            SELECT name INTO _alarm_name FROM alarm_list WHERE id = _alarm_list_id;
			SELECT id INTO _alarm_temp_id FROM alarm_temp WHERE node_id = new.id AND alarm_list_id = _alarm_list_id;
			
            IF _alarm_temp_id IS NULL THEN 
				INSERT INTO alarm_temp (node_id,dtime,alarm_list_id,alarm_label,severity_id) 
				VALUES (new.id,_alarm_time,_alarm_list_id,_alarm_name,_alarm_severity_id);
			ELSE
				UPDATE alarm_temp SET severity_id = _alarm_severity_id WHERE id = _alarm_temp_id;
            END IF;
			
        ELSE
			
			_alarm_list_id  := 5;
			SELECT id INTO _alarm_temp_id FROM alarm_temp WHERE node_id = new.id AND alarm_list_id = _alarm_list_id;
            UPDATE alarm_log SET dtime_end = _alarm_time WHERE id = _alarm_temp_id;
            DELETE FROM alarm_temp WHERE node_id = new.id AND alarm_list_id = _alarm_list_id;
			
        END IF;
		
        RETURN NEW;
		
    END;
    $$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION trg_alarm_insert() 
    RETURNS TRIGGER AS $$
    DECLARE 
        
        -- Trigger alarm log
        -- 
        -- Author : Asep Maryana
        -- Email  : maryana@hariff.com
        -- Website: www.asepmaryana.net
        -- Created: 29 Sept 2016 12:00 WIB
        
        
    BEGIN
        
        INSERT INTO alarm_log (id,node_id,dtime,alarm_list_id,alarm_label,severity_id) 
        VALUES (new.id,new.node_id,new.dtime,new.alarm_list_id,new.alarm_label,new.severity_id);
        
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    
CREATE OR REPLACE FUNCTION trg_alarm_delete() 
    RETURNS TRIGGER AS $$
    DECLARE 
        
        -- Trigger alarm delete log
        -- 
        -- Author : Asep Maryana
        -- Email  : maryana@hariff.com
        -- Website: www.asepmaryana.net
        -- Created: 29 Sept 2016 12:00 WIB
        
        
    BEGIN
        
        UPDATE alarm_log SET dtime_end = now() WHERE id = old.id;
        
        RETURN OLD;
    END;
    $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION run_hour_node(_node_id INT, _ddate DATE) 
    RETURNS REAL AS $$
    
    DECLARE 
        _run_time REAL = 0;
        _data RECORD;
        _start TIMESTAMP;
        _stop TIMESTAMP;
        _curr_status SMALLINT;
        _old_status SMALLINT;
    BEGIN
        
        IF NOT EXISTS(SELECT id FROM running_hour WHERE node_id = _node_id AND ddate = _ddate) THEN
            INSERT INTO running_hour(node_id, ddate) VALUES (_node_id, _ddate);
        END IF;
        
        _curr_status := 0;
        _old_status  := 0;
        
        _start := NULL;
        _stop  := NULL;
        
        FOR _data IN SELECT * FROM data_log WHERE node_id = _node_id AND dtime::DATE = _ddate ORDER BY dtime ASC LOOP 
            
            _curr_status := _data.genset_status;
            
            IF _curr_status = 1 AND _start IS NULL THEN 
                _start := _data.dtime;
            END IF;
            
            IF _curr_status = 0 AND _old_status = 1 THEN
                _stop := _data.dtime;
                _run_time := _run_time + DATEDIFF('second', _start, _stop);
                
                _start := NULL;
                _stop  := NULL; 
            END IF;
            
            _old_status  := _curr_status;
            
        END LOOP;
        
        SELECT dtime INTO _stop
        FROM data_log
        WHERE node_id = _node_id 
        AND dtime::DATE = _ddate ORDER BY dtime DESC 
        LIMIT 1;
        
        IF _start != _stop THEN
            _run_time := _run_time + DATEDIFF('second', _start, _stop);
        END IF;
        
        _run_time := _run_time / 3600;
        
        UPDATE running_hour 
        SET val = _run_time
        WHERE node_id = _node_id 
        AND ddate = _ddate;
        
        RETURN _run_time;
        
    END;
    $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION after_datalog_insert() 
    RETURNS TRIGGER AS $$
    DECLARE 
        
        -- Trigger before insert data_log
        -- 
        -- Author : Asep Maryana
        -- Email  : asep.maryana@sinergiteknologi.com
        -- Website: www.asepmaryana.net
        -- Created: 07 March 2017 09:00 WIB
        
        _run_time REAL = 0;
        
    BEGIN
        
        SELECT SUM(val) INTO _run_time
        FROM running_hour
        WHERE node_id = NEW.node_id;
        
        UPDATE data_log SET run_hour = _run_time WHERE id = NEW.id;
        
        RETURN NEW;
        
    END;
    $$ LANGUAGE plpgsql;