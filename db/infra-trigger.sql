CREATE TRIGGER trg_node_update 
    BEFORE UPDATE 
    ON node 
    FOR EACH ROW 
    EXECUTE PROCEDURE trg_node_update();

CREATE TRIGGER trg_alarm_insert 
    AFTER INSERT 
    ON alarm_temp 
    FOR EACH ROW 
    EXECUTE PROCEDURE trg_alarm_insert();

/*
CREATE TRIGGER trg_alarm_delete 
    BEFORE DELETE 
    ON alarm_temp 
    FOR EACH ROW 
    EXECUTE PROCEDURE trg_alarm_delete();
*/

CREATE TRIGGER trg_datalog_insert 
    BEFORE INSERT ON data_log 
    FOR EACH ROW 
    EXECUTE PROCEDURE before_datalog_insert();