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
        -- Modified: 28 Jul 2018 10:25 WIB
        
		_alarm_temp_id		BIGINT;
        _alarm_list_id      INT;
        _alarm_name         VARCHAR(50);
        _alarm_severity_id  INT;        
        _alarm_time			TIMESTAMP;
		_alarm_tolerance    INT;
        _batt_volt          REAL;
        _day                VARCHAR(3);
        _operator           RECORD;
        _sms                VARCHAR(160);
        
    BEGIN
        
        _alarm_time	:= new.updated_at;
		
        IF _alarm_time IS NULL THEN
            _alarm_time := now();
        END IF;
        
        -- read day of week
        _day    := get_day_name(now()::TIMESTAMP);
        
        -- read config
        SELECT alarm_tolerance, batt_volt INTO _alarm_tolerance, _batt_volt FROM config WHERE id = '1';
        IF _alarm_tolerance IS NULL THEN
            _alarm_tolerance := 120;
        END IF;
        
        IF new.updated_at <> old.updated_at AND new.updated_at IS NOT NULL THEN 
            
            new.opr_status_id = 1;
			_alarm_time	:= new.updated_at;
            INSERT INTO data_log (node_id,dtime,genset_vr,genset_vs,genset_vt,batt_volt,genset_batt_volt,timer_genset_on,timer_genset_off,run_hour,run_hour_tresh,genset_status,genset_on_fail,genset_off_fail,low_fuel,recti_fail,batt_low,sin_high_temp,eng_high_temp,oil_pressure,maintain_status,recti_status) 
            VALUES (new.id,new.updated_at,new.genset_vr,new.genset_vs,new.genset_vt,new.batt_volt,new.genset_batt_volt,new.timer_genset_on,new.timer_genset_off,new.run_hour,new.run_hour_tresh,new.genset_status,new.genset_on_fail,new.genset_off_fail,new.low_fuel,new.recti_fail,new.batt_low,new.sin_high_temp,new.eng_high_temp,new.oil_pressure,new.maintain_status,new.recti_status);
                        
        END IF;
        
        -- if status genset was changed
        IF new.genset_status <> old.genset_status THEN
            IF new.genset_status = 1 THEN
                -- if gensen on
                new.next_off     := new.updated_at + make_interval(mins => (new.timer_genset_on + _alarm_tolerance));
                new.last_off     := old.updated_at;
            ELSE
                -- if genset off
                new.next_on     := new.updated_at + make_interval(mins => (new.timer_genset_off + _alarm_tolerance));
                new.last_on     := old.updated_at;
            END IF;
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
                    
                    -- build sms text
                    _sms    := concat(upper(_alarm_time), chr(13), new.name, ' [', new.phone, ']', chr(13), to_char(_alarm_time, 'DD-MON-YY HH24:MI'), ' WIB');
                    
                    -- send sms notif if low fuel was occured
                    FOR _operator IN EXECUTE 'SELECT phone FROM operator WHERE enabled=1 AND ' || _day || '=1' 
                    LOOP
                        INSERT INTO outbox(recipient, text, create_date) VALUES (_operator.phone, _sms, _alarm_time);
                    END LOOP;
                    
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
        
        IF new.batt_volt <> old.batt_volt THEN
            _alarm_list_id  := 5;
			_alarm_severity_id := 1;
            
            -- alarm batt volt occured when < _batt_volt
            IF new.batt_volt < _batt_volt THEN
                SELECT name,severity_id INTO _alarm_name,_alarm_severity_id FROM alarm_list WHERE id = _alarm_list_id;
                SELECT id INTO _alarm_temp_id FROM alarm_temp WHERE node_id = new.id AND alarm_list_id = _alarm_list_id;
                
                IF _alarm_temp_id IS NULL THEN 
                    INSERT INTO alarm_temp (node_id,dtime,alarm_list_id,alarm_label,severity_id) 
					VALUES (new.id,_alarm_time,_alarm_list_id,_alarm_name,_alarm_severity_id);
                    
                    -- build sms text
                    _sms    := concat(upper(_alarm_name), chr(13), new.name, ' [', new.phone, ']', chr(13), to_char(_alarm_time, 'DD-MON-YY HH24:MI'), ' WIB');
                    
                    -- send sms notif if low fuel was occured
                    FOR _operator IN EXECUTE 'SELECT phone FROM operator WHERE enabled=1 AND ' || _day || '=1' 
                    LOOP
                        INSERT INTO outbox(recipient, text, create_date) VALUES (_operator.phone, _sms, _alarm_time);
                    END LOOP;
                END IF;
                
            ELSE
                _alarm_list_id  := 5;
                SELECT id INTO _alarm_temp_id FROM alarm_temp WHERE node_id = new.id AND alarm_list_id = _alarm_list_id;
                UPDATE alarm_log SET dtime_end = _alarm_time WHERE id = _alarm_temp_id;
                DELETE FROM alarm_temp WHERE node_id = new.id AND alarm_list_id = _alarm_list_id;
            END IF;
            
        END IF;
        
        -- add comm lost handler
        IF new.opr_status_id <> old.opr_status_id THEN
            _alarm_list_id  := 10;
            
            -- if operational
            IF new.opr_status_id = 1 OR new.opr_status_id = 2 THEN
                DELETE FROM alarm_temp WHERE node_id = new.id AND alarm_list_id = _alarm_list_id;
                
            -- if comm lost
            ELSE
                SELECT name,severity_id INTO _alarm_name,_alarm_severity_id FROM alarm_list WHERE id = _alarm_list_id;
                SELECT id INTO _alarm_temp_id FROM alarm_temp WHERE node_id = new.id AND alarm_list_id = _alarm_list_id;
                
                IF _alarm_temp_id IS NULL THEN 
                    INSERT INTO alarm_temp (node_id,dtime,alarm_list_id,alarm_label,severity_id) 
					VALUES (new.id,now(),_alarm_list_id,_alarm_name,_alarm_severity_id);
                    
                    -- build sms text
                    _sms    := concat(upper(_alarm_name), chr(13), new.name, ' [', new.phone, ']', chr(13), to_char(now(), 'DD-MON-YY HH24:MI'), ' WIB');
                    
                    -- send sms notif if low fuel was occured
                    FOR _operator IN EXECUTE 'SELECT phone FROM operator WHERE enabled=1 AND ' || _day || '=1' 
                    LOOP
                        -- INSERT INTO outbox(recipient, text, create_date) VALUES (_operator.phone, _sms, _alarm_time);
                    END LOOP;
                END IF;
                
            END IF;
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

CREATE OR REPLACE FUNCTION trg_operator_crud() 
    RETURNS TRIGGER AS $$
    DECLARE 
        
        -- Trigger before insert , update and delete operator
        -- 
        -- Author : Asep Maryana
        -- Email  : asep.maryana@sinergiteknologi.com
        -- Website: www.asepmaryana.net
        -- Created: 29 Jul 2017 14:30 WIB
        
        _day    VARCHAR(160);
        
    BEGIN
        
        IF (TG_OP = 'DELETE') THEN
            INSERT INTO outbox(recipient,text,create_date,status,gateway_id,message_type) 
            VALUES (old.phone, CONCAT('Hi, ',old.name, chr(10),'Your CDC schedule have been deleted.'), now(), 'U', '*', 'N');
            
            RETURN OLD;
        
        ELSE
            _day    := '';
            
            IF new.mon  = 1 THEN _day   := CONCAT(_day, '- Monday', chr(10)); END IF;
            IF new.tue  = 1 THEN _day   := CONCAT(_day, '- Tuesday', chr(10)); END IF;
            IF new.wed  = 1 THEN _day   := CONCAT(_day, '- Wednesday', chr(10)); END IF;
            IF new.thu  = 1 THEN _day   := CONCAT(_day, '- Thursday', chr(10)); END IF;
            IF new.fri  = 1 THEN _day   := CONCAT(_day, '- Friday', chr(10)); END IF;
            IF new.sat  = 1 THEN _day   := CONCAT(_day, '- Saturday', chr(10)); END IF;
            IF new.sun  = 1 THEN _day   := CONCAT(_day, '- Sunday', chr(10)); END IF;
            
            IF (TG_OP = 'INSERT') THEN
                INSERT INTO outbox(recipient,text,create_date,status,gateway_id,message_type) 
                VALUES (new.phone, CONCAT('Hi, ',new.name, chr(10),'You have added to CDC with schedule:', chr(10), _day), now(), 'U', '*', 'N');
            ELSE
                INSERT INTO outbox(recipient,text,create_date,status,gateway_id,message_type) 
                VALUES (new.phone, CONCAT('Hi, ',new.name, chr(10),'Your CDC schedule have been modified:', chr(10), _day), now(), 'U', '*', 'N');
            END IF;
            
            RETURN NEW;
        
        END IF;
        
    END;
    $$ LANGUAGE plpgsql;
    
CREATE OR REPLACE FUNCTION get_day_name(_dtime TIMESTAMP) 
    RETURNS VARCHAR(3) AS $$
    
    DECLARE 
        _day VARCHAR(3);
    BEGIN
        
        IF date_part('hour', _dtime) < 9 THEN
            _dtime  := _dtime - interval '24 hours';
        END IF;
        
        SELECT lower(to_char(_dtime, 'Dy')) INTO _day;
        
        RETURN _day;
        
    END;
    $$ LANGUAGE plpgsql;