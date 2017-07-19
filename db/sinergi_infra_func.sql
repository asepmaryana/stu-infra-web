CREATE OR REPLACE FUNCTION DATEDIFF (units VARCHAR(30), start_t TIMESTAMP, end_t TIMESTAMP)
RETURNS INT AS $$

DECLARE
    diff_interval INTERVAL; 
    diff INT = 0;
    years_diff INT = 0;

BEGIN
    IF units IN ('yy', 'yyyy', 'year', 'mm', 'm', 'month') THEN
        years_diff = DATE_PART('year', end_t) - DATE_PART('year', start_t);
        IF units IN ('yy', 'yyyy', 'year') THEN
            RETURN years_diff;
        ELSE
            RETURN years_diff * 12 + (DATE_PART('month', end_t) - DATE_PART('month', start_t)); 
        END IF;
    END IF;
    
    diff_interval = end_t - start_t;
    diff = diff + DATE_PART('day', diff_interval);
    
    IF units IN ('wk', 'ww', 'week') THEN
        diff = diff/7;
        RETURN diff;
    END IF;
    
    IF units IN ('dd', 'd', 'day') THEN
        RETURN diff;
    END IF;
    
    diff = diff * 24 + DATE_PART('hour', diff_interval);
    
    IF units IN ('hh', 'hour') THEN
        RETURN diff;
    END IF;
    
    diff = diff * 60 + DATE_PART('minute', diff_interval);
    
    IF units IN ('mi', 'n', 'minute') THEN
        RETURN diff;
    END IF;
    
    diff = diff * 60 + DATE_PART('second', diff_interval);
    
     RETURN diff;
     
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION DATEDIFFTIME (units VARCHAR(30), start_t TIME, end_t TIME) 
RETURNS INT AS $$

DECLARE
    diff_interval INTERVAL; 
    diff INT = 0;
    
BEGIN
    diff_interval = end_t - start_t;
    
    diff = DATE_PART('hour', diff_interval);
    
    IF units IN ('hh', 'hour') THEN
        RETURN diff;
    END IF;
    
    diff = diff * 60 + DATE_PART('minute', diff_interval);
    
    IF units IN ('mi', 'n', 'minute') THEN
        RETURN diff;
    END IF;
    
    diff = diff * 60 + DATE_PART('second', diff_interval);
    
    RETURN diff;
    
END;
$$ LANGUAGE plpgsql;