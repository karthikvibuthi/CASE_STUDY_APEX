BEGIN
    -- Check if user is a PLANNER or an APPROVER
    IF APEX_ACL.HAS_USER_ROLE(p_user_name => :APP_USER, p_role_static_id => 'PLANNER') OR
       APEX_ACL.HAS_USER_ROLE(p_user_name => :APP_USER, p_role_static_id => 'APPROVER') OR APEX_ACL.HAS_USER_ROLE(p_user_name => :APP_USER, p_role_static_id => 'ADMIN') THEN
       RETURN TRUE;
    ELSE
       RETURN FALSE;
    END IF;
END;
