DECLARE
    v_year          NUMBER;
    v_month         NUMBER;
    v_dealer_code   VARCHAR2(50);
    v_brand         VARCHAR2(50);
    v_model_name    VARCHAR2(100);
    v_trim          VARCHAR2(100);
    v_model_code    VARCHAR2(50);

    v_currency      VARCHAR2(10);
    v_units         NUMBER;
    v_net_price     NUMBER;
    v_discount      NUMBER;
    v_promo_flag    CHAR(1);
    v_inventory_end NUMBER;
    v_blackout_flag CHAR(1);

    v_dealer_id     NUMBER;
    v_model_id      NUMBER;
    v_calendar_id   NUMBER;

BEGIN
    ----------------------------------------------------------------------
    -- 1. TRUNCATE TARGET FACT TABLE
    ----------------------------------------------------------------------
    EXECUTE IMMEDIATE 'TRUNCATE TABLE BMW_SALES_HISTORY';

    ----------------------------------------------------------------------
    -- 2. LOOP THROUGH PARSED APEX DATA FILE
    ----------------------------------------------------------------------
    FOR r IN (
        SELECT
            P.col001 AS year_num,
            P.col002 AS month_num,
            P.col003 AS dealer_code,
            P.col006 AS brand,
            P.col007 AS model_name,
            P.col008 AS trim,
            P.col009 AS model_code,

            P.col010 AS currency,
            P.col011 AS units,
            P.col012 AS net_price,
            P.col013 AS discount,
            P.col014 AS promo_flag,
            P.col015 AS inventory_end,
            P.col016 AS blackout_flag
        FROM APEX_APPLICATION_TEMP_FILES F,
             TABLE(
                 APEX_DATA_PARSER.parse(
                     p_content         => F.blob_content,
                     p_file_name       => F.filename,
                     p_add_headers_row => 'Y'
                 )
             ) P
        WHERE F.name = :P7_FILE
          AND p.line_number > 1     -- skip header
    )
    LOOP
        ------------------------------------------------------------------
        -- 3. MAP DIMENSION KEYS
        ------------------------------------------------------------------

        -- Dealer lookup
        SELECT dealer_id
          INTO v_dealer_id
          FROM bmw_dealers
         WHERE dealer_code = r.dealer_code;

        -- Model lookup
        SELECT model_id
          INTO v_model_id
          FROM bmw_models
         WHERE model_code = r.model_code
           AND brand = r.brand;

        -- Calendar lookup (year, month → date → calendar_id)
        SELECT calendar_id
          INTO v_calendar_id
          FROM bmw_sales_calendar
         WHERE year_num = r.year_num
           AND month_num = r.month_num;

        ------------------------------------------------------------------
        -- 4. VALIDATIONS
        ------------------------------------------------------------------
        IF r.units < 0 OR r.net_price < 0 OR r.discount < 0 THEN
            INSERT INTO bmw_audit_log (
                username, action_type, table_name, record_id, old_value, new_value
            ) VALUES (
                v('APP_USER'),
                'REJECT',
                'BMW_SALES_HISTORY',
                r.dealer_code || '-' || r.model_code,
                NULL,
                'Invalid negative values'
            );
            CONTINUE;
        END IF;

        ------------------------------------------------------------------
        -- 5. INSERT INTO FACT TABLE
        ------------------------------------------------------------------
        INSERT INTO bmw_sales_history (
            dealer_id,
            model_id,
            calendar_id,
            units,
            net_price,
            currency,
            discount,
            promo_flag,
            inventory_end,
            blackout_flag
        )
        VALUES (
            v_dealer_id,
            v_model_id,
            v_calendar_id,
            r.units,
            r.net_price,
            r.currency,
            r.discount,
            r.promo_flag,
            r.inventory_end,
            r.blackout_flag
        );

    END LOOP;

    COMMIT;
END;

