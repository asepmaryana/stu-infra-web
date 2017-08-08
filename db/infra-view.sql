DROP VIEW IF EXISTS alarm_temp_view;
CREATE VIEW alarm_temp_view AS 
    SELECT alt.*,
        als.name as severity,        
        node.name as site,
        node.subnet_id,
        node.phone,
        subnet.name as area,
        (SELECT parent_id FROM subnet WHERE id = (SELECT subnet_id FROM node WHERE id = alt.node_id)) as area_id,
		(SELECT id FROM subnet WHERE id = 
            (SELECT parent_id FROM subnet WHERE id = 
                (SELECT subnet_id FROM node WHERE id = alt.node_id)))
        as region_id,
        (SELECT name FROM subnet WHERE id = 
            (SELECT parent_id FROM subnet WHERE id = 
                (SELECT subnet_id FROM node WHERE id = alt.node_id)))
        as region,
        to_char(alt.dtime, 'DD-MON-YY HH24:MI') as ddtime         
    FROM alarm_temp alt 
    LEFT JOIN node ON alt.node_id = node.id 
    LEFT JOIN subnet ON node.subnet_id = subnet.id 
    LEFT JOIN alarm_list al ON alt.alarm_list_id = al.id 
    LEFT JOIN severity als ON alt.severity_id = als.id;


DROP VIEW IF EXISTS alarm_log_view;
CREATE VIEW alarm_log_view AS 
    SELECT alt.*,
        als.name as severity,        
        node.name as site,
        node.phone,
        subnet.name as area,
		(SELECT id FROM subnet WHERE id = 
            (SELECT parent_id FROM subnet WHERE id = 
                (SELECT subnet_id FROM node WHERE id = alt.node_id)))
        as region_id,
        (SELECT name FROM subnet WHERE id = 
            (SELECT parent_id FROM subnet WHERE id = 
                (SELECT subnet_id FROM node WHERE id = alt.node_id)))
        as region,
        to_char(alt.dtime, 'DD-MON-YY HH24:MI') as ddtime,
        to_char(alt.dtime_end, 'DD-MON-YY HH24:MI') as ddtime_end 
    FROM alarm_log alt 
    LEFT JOIN node ON alt.node_id = node.id 
    LEFT JOIN subnet ON node.subnet_id = subnet.id 
    LEFT JOIN alarm_list al ON alt.alarm_list_id = al.id 
    LEFT JOIN severity als ON alt.severity_id = als.id;
    
DROP VIEW IF EXISTS region_view;
CREATE VIEW region_view AS 
    SELECT * FROM subnet WHERE parent_id IS NULL ;
   
DROP VIEW IF EXISTS area_view;
CREATE VIEW area_view AS 
    SELECT area.*, region.name AS region 
    FROM subnet area 
    LEFT JOIN subnet region ON area.parent_id = region.id 
    WHERE area.parent_id IN (SELECT id FROM subnet WHERE parent_id IS NULL) ; 

DROP VIEW IF EXISTS site_view;
CREATE VIEW site_view AS 
    SELECT site.*, 
        area.id AS area_id, area.name AS area, 
        region.id AS region_id, 
        region.name AS region
    FROM subnet site  
    LEFT JOIN subnet area ON site.parent_id = area.id
    LEFT JOIN subnet region ON area.parent_id = region.id 
    WHERE site.parent_id IN (SELECT id FROM subnet WHERE parent_id IN (SELECT id FROM subnet WHERE parent_id IS NULL)) ;
    
DROP VIEW IF EXISTS node_view;
CREATE VIEW node_view AS 
    SELECT node.*,
        site.name AS site,
        site.area_id,
        site.area,
        site.region_id,
        site.region,
        cust.name AS customer,
        op.name AS status
    FROM node 
    LEFT JOIN site_view site ON node.subnet_id = site.id 
    LEFT JOIN customer cust ON node.customer_id = cust.id
    LEFT JOIN opr_status op ON node.opr_status_id = op.id;
    
DROP VIEW IF EXISTS data_log_view;
CREATE VIEW data_log_view AS 
    SELECT p.*, n.name, n.site, to_char(p.dtime, 'DD/MM/YYYY HH24:MI:SS') as ddtime, to_char(p.dtime, 'Month DD, YYYY HH24:MI:SS') as jsdate
    FROM data_log p  
    LEFT JOIN node_view n ON p.node_id = n.id;