PROGRAM ConveyorSortingControl
VAR
    i_Start_PB     AT %I0.0 : BOOL;
    i_Prox_Sensor  AT %I0.1 : BOOL;
    i_EStop_Mon    AT %I0.2 : BOOL;
    i_Stop_PB      AT %I0.3 : BOOL;
    i_Tall_Sensor  AT %I0.4 : BOOL;

    q_Conv_Motor   AT %Q1.0 : BOOL;
    q_Reject_Push  AT %Q1.1 : BOOL;
    q_Warn_Light   AT %Q1.2 : BOOL;

    s_CurrentState : INT := 1;
    b_EStop_Fault  : BOOL := FALSE;
    b_Batch_Comp   : BOOL := FALSE;
    
    fb_Prox_Edge   : R_TRIG;
    fb_Tall_Edge   : R_TRIG;
    b_Count_Pulse  : BOOL;
    b_Tall_Detected: BOOL;

    fb_Transit_TON : TON;
    fb_Batch_CTU   : CTU;
END_VAR

IF NOT i_EStop_Mon THEN
    b_EStop_Fault := TRUE;
    s_CurrentState := 4;
END_IF;

IF i_EStop_Mon AND i_Start_PB AND b_EStop_Fault THEN
    b_EStop_Fault := FALSE;
    s_CurrentState := 1;
END_IF;

fb_Prox_Edge(CLK := i_Prox_Sensor);
b_Count_Pulse := fb_Prox_Edge.Q;

fb_Tall_Edge(CLK := i_Tall_Sensor);
b_Tall_Detected := fb_Tall_Edge.Q;

CASE s_CurrentState OF
    1:
        q_Conv_Motor  := FALSE;
        q_Reject_Push := FALSE;
        q_Warn_Light  := FALSE;
        
        IF i_Start_PB AND NOT(i_Stop_PB) AND i_EStop_Mon AND NOT(b_EStop_Fault) THEN
            s_CurrentState := 2;
        END_IF;

    2:
        q_Conv_Motor := TRUE;
        q_Warn_Light := FALSE;
        
        IF i_Prox_Sensor AND NOT(b_EStop_Fault) AND NOT(b_Batch_Comp) THEN
            s_CurrentState := 3;
        END_IF;
        
        IF NOT i_Stop_PB THEN
            s_CurrentState := 1;
        END_IF;

    3:
        q_Conv_Motor := TRUE; 

        fb_Transit_TON(IN := i_Tall_Sensor, PT := T#1500MS);
        
        IF fb_Transit_TON.Q THEN
            q_Reject_Push := TRUE;
        ELSE
            q_Reject_Push := FALSE;
        END_IF;

        fb_Batch_CTU(CU := b_Count_Pulse, RESET := (s_CurrentState = 1), PV := 5);
        b_Batch_Comp := fb_Batch_CTU.Q;

        IF NOT i_Prox_Sensor AND NOT(q_Reject_Push) THEN
            s_CurrentState := 2;
        END_IF;

    4:
        q_Conv_Motor  := FALSE;
        q_Reject_Push := FALSE;
        q_Warn_Light  := TRUE;
        
END_CASE;
END_PROGRAM
