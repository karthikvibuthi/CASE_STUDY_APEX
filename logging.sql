BEGIN
    BMW_FP_LOG_EVENT(
        p_action_type =>
            CASE 
                WHEN :REQUEST = 'CREATE' THEN 'SCENARIO_CREATE'
                WHEN :REQUEST = 'UPDATE' THEN 'SCENARIO_UPDATE'
                WHEN :REQUEST = 'DELETE' THEN 'SCENARIO_DELETE'
                ELSE 'SCENARIO_UNKNOWN'
            END,
        p_entity_type => 'SCENARIO',
        p_entity_id   => :P_SCENARIO_ID,
        p_details     => 'Scenario = ' || :P6_SCENARIO_NAME
    );
END;
