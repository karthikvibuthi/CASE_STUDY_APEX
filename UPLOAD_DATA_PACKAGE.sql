DECLARE
    v_year          NUMBER;
    v_month         NUMBER;
    v_dealer_code   VARCHAR2(50);
    v_brand         VARCHAR2(50);
    v_model_name    VARCHAR2(100);
    v_trim          VARCHAR2(100);
    v_model_code    VARCHAR2(50);

    v_currency      VARCHAR2(3);
    v_units         NUMBER;
    v_net_price     NUMBER;
    v_discount      NUMBER;
    v_promo_flag    NUMBER;
    v_inventory_end NUMBER;
    v_blackout_num  NUMBER(1);

    -- v_dealer_id     NUMBER;
    -- v_model_id      NUMBER;
    -- v_calendar_id   NUMBER;
    DATE_VALUE       DATE;

    v_load_id       NUMBER := TO_NUMBER(TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISSFF3'));
    v_raw_row       CLOB;

    PROCEDURE log_reject(
        p_row_num    NUMBER,
        p_dealer_cd  VARCHAR2,
        p_model_cd   VARCHAR2,
        p_reason     VARCHAR2,
        p_raw_row    CLOB
    ) IS
    BEGIN
        INSERT INTO BMW_SALES_HISTORY_REJECTS (
            load_id,
            row_num,
            dealer_code,
            model_code,
            error_reason,
            raw_row
        ) VALUES (
            v_load_id,
            p_row_num,
            p_dealer_cd,
            p_model_cd,
            p_reason,
            p_raw_row
        );
    END log_reject;
BEGIN
    ----------------------------------------------------------------------
    -- 1. TRUNCATE TARGET FACT TABLE
    ----------------------------------------------------------------------
    EXECUTE IMMEDIATE 'TRUNCATE TABLE BMW_SALES_HISTORY';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE BMW_SALES_HISTORY_REJECTS';

    ----------------------------------------------------------------------
    -- 2. LOOP THROUGH PARSED APEX DATA FILE
    ----------------------------------------------------------------------
    FOR r IN (
        SELECT
            P.line_number AS row_num,
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
        v_raw_row := TO_CLOB(
            'YEAR=' || NVL(TO_CHAR(r.year_num), 'NULL') || ',' ||
            'MONTH=' || NVL(TO_CHAR(r.month_num), 'NULL') || ',' ||
            'DEALER_CODE=' || NVL(r.dealer_code, 'NULL') || ',' ||
            'BRAND=' || NVL(r.brand, 'NULL') || ',' ||
            'MODEL_NAME=' || NVL(r.model_name, 'NULL') || ',' ||
            'TRIM=' || NVL(r.trim, 'NULL') || ',' ||
            'MODEL_CODE=' || NVL(r.model_code, 'NULL') || ',' ||
            'CURRENCY=' || NVL(r.currency, 'NULL') || ',' ||
            'UNITS=' || NVL(TO_CHAR(r.units), 'NULL') || ',' ||
            'NET_PRICE=' || NVL(TO_CHAR(r.net_price), 'NULL') || ',' ||
            'DISCOUNT=' || NVL(TO_CHAR(r.discount), 'NULL') || ',' ||
            'PROMO_FLAG=' || NVL(r.promo_flag, 'NULL') || ',' ||
            'INVENTORY_END=' || NVL(TO_CHAR(r.inventory_end), 'NULL') || ',' ||
            'BLACKOUT_FLAG=' || NVL(r.blackout_flag, 'NULL')
        );

        v_dealer_code := TRIM(r.dealer_code);
        v_brand       := UPPER(TRIM(r.brand));
        v_model_code  := TRIM(r.model_code);
        v_units       := r.units;
        v_net_price   := r.net_price;
        v_discount    := r.discount;
        v_inventory_end := r.inventory_end;
        v_year        := r.year_num;
        v_month       := r.month_num;

        ------------------------------------------------------------------
        -- 3. VALIDATION RULES
        ------------------------------------------------------------------
        IF v_dealer_code IS NULL OR v_dealer_code NOT IN ('D001','D002','D003','D004','D005','D006','D007','D008','D009','D010') THEN
            log_reject(r.row_num, v_dealer_code, v_model_code, 'Dealer code is required or not valid', v_raw_row);
            CONTINUE;
        END IF;

        IF v_brand IS NULL OR v_brand NOT IN ('BMW', 'MINI') THEN
            log_reject(r.row_num, v_dealer_code, v_model_code, 'Brand must be BMW or MINI', v_raw_row);
            CONTINUE;
        END IF;

        IF v_model_code IS NULL OR v_model_code NOT IN ('MINI-Ctrymn-S4', 'BMW-X3-30i', 'BMW-330i', 'MINI-CooperS') THEN
            log_reject(r.row_num, v_dealer_code, v_model_code, 'Model code is required or not valid', v_raw_row);
            CONTINUE;
        END IF;

        IF v_units IS NULL OR v_units < 0 THEN
            log_reject(r.row_num, v_dealer_code, v_model_code, 'Units must be >= 0', v_raw_row);
            CONTINUE;
        END IF;

        IF v_net_price IS NULL OR v_net_price < 0 THEN
            log_reject(r.row_num, v_dealer_code, v_model_code, 'Net price must be >= 0', v_raw_row);
            CONTINUE;
        END IF;

        IF v_inventory_end IS NULL OR v_inventory_end < 0 THEN
            log_reject(r.row_num, v_dealer_code, v_model_code, 'Inventory_end must be >= 0', v_raw_row);
            CONTINUE;
        END IF;

        IF v_discount IS NULL OR v_discount < 0 THEN
            log_reject(r.row_num, v_dealer_code, v_model_code, 'Discount must be >= 0', v_raw_row);
            CONTINUE;
        END IF;

        IF r.promo_flag IS NULL OR TRIM(r.promo_flag) NOT IN ('0', '1') THEN
            log_reject(r.row_num, v_dealer_code, v_model_code, 'Promo flag must be 0 or 1', v_raw_row);
            CONTINUE;
        ELSE
            v_promo_flag := TO_NUMBER(TRIM(r.promo_flag));
        END IF;

        IF r.blackout_flag IS NULL OR TRIM(r.blackout_flag) NOT IN ('0', '1') THEN
            log_reject(r.row_num, v_dealer_code, v_model_code, 'Blackout flag must be 0 or 1', v_raw_row);
            CONTINUE;
        ELSE
            v_blackout_num := TO_NUMBER(TRIM(r.blackout_flag));
        END IF;

        v_currency := SUBSTR(UPPER(TRIM(r.currency)), 1, 3);
        IF v_currency NOT IN ('USD', 'EUR') THEN
            log_reject(r.row_num, v_dealer_code, v_model_code, 'Currency must be USD or EUR', v_raw_row);
            CONTINUE;
        END IF;

        IF v_year IS NULL OR v_year < 2010 OR v_year > 2035 THEN
            log_reject(r.row_num, v_dealer_code, v_model_code, 'Year must be between 2010 and 2035', v_raw_row);
            CONTINUE;
        END IF;

        IF v_month IS NULL OR v_month < 1 OR v_month > 12 THEN
            log_reject(r.row_num, v_dealer_code, v_model_code, 'Month must be between 1 and 12', v_raw_row);
            CONTINUE;
        END IF;

        ------------------------------------------------------------------
        -- 4. MAP DIMENSION KEYS
        ------------------------------------------------------------------
        BEGIN
            SELECT dealer_code
              INTO v_dealer_code
              FROM bmw_dealers
             WHERE dealer_code = v_dealer_code;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                log_reject(r.row_num, v_dealer_code, v_model_code, 'Dealer code not found in BMW_DEALERS', v_raw_row);
                CONTINUE;
        END;

        BEGIN
            SELECT model_code
              INTO v_model_code
              FROM bmw_models
             WHERE model_code = v_model_code
               AND brand = v_brand;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                log_reject(r.row_num, v_dealer_code, v_model_code, 'Model code not found in BMW_MODELS', v_raw_row);
                CONTINUE;
        END;

        BEGIN
            SELECT DATE_VALUE
              INTO DATE_VALUE
              FROM bmw_sales_calendar
             WHERE date_value = TO_DATE(
                                   v_year || '-' || LPAD(v_month, 2, '0') || '-01',
                                   'YYYY-MM-DD'
                               );
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                log_reject(r.row_num, v_dealer_code, v_model_code, 'Calendar date not found for supplied year/month', v_raw_row);
                CONTINUE;
        END;

        ------------------------------------------------------------------
        -- 5. INSERT INTO FACT TABLE
        ------------------------------------------------------------------
        INSERT INTO bmw_sales_history (
            dealer_code,
            model_code,
            DATE_VALUE,
            units,
            net_price,
            currency,
            discount,
            promo_flag,
            inventory_end,
            blackout_flag
        )
        VALUES (
            v_dealer_code,
            v_model_code,
            DATE_VALUE,
            v_units,
            v_net_price,
            v_currency,
            v_discount,
            v_promo_flag,
            v_inventory_end,
            v_blackout_num
        );

    END LOOP;

    COMMIT;
END;
