function ENA = setupTest(visaAddress)
    
    % Remove all interfaces to instrument
    instrreset
    
    % find all previously created objects
    oldobjs = instrfind;
    
    % If there are any existing objects
    if (~isempty(oldobjs))
        % close the connection to the instrument
        fclose(oldobjs);
        % and free up the object resources
        delete(oldobjs);
    end
    
    % Remove the object list from the workspace.
    clear oldobjs;
    
    % Define ENA interface, this is the VISA resource string. Replace this VISA
    % resource string with your ENA VISA resource string as appropriate. 
    ENA = visa('agilent', visaAddress); %ENA address
    
    % Buffer size must precede open command
    set(ENA,'InputBufferSize', 640000);
    set(ENA,'OutputBufferSize', 640000);
    
    % Open session to ENA based on VISA resource string
    fopen(ENA);
    
    % Clear the event status registers and all errors which may be in the ENA's error queue.
    fprintf(ENA, '*CLS');
    
    % Check to ensure the error queue is clear. Response should be '+0, No Error'
    fprintf(ENA, 'SYST:ERR?');
    errIdentifyStart = fscanf(ENA, '%c');
    fprintf(strcat('\nThe initial error query results string is:\t',errIdentifyStart))
    
    % Query instrument identification string
    fprintf(ENA, '*IDN?'); 
    idn = fscanf(ENA, '%c');
    fprintf(strcat('\nThe identification string is:\t',idn))
    
    % ENA timeout is set to 15 (seconds) to allow for longer sweep times. 
    set(ENA, 'Timeout', 15);
    
    % Trigger mode is set to initiate continuous on and trigger source as bus
    fprintf(ENA, 'INIT:CONT ON');
    %fprintf(ENA, 'TRIG:SOUR BUS');
    
    % Trigger a single sweep and wait for trigger completion via *OPC? query i.e. (operation complete). 
    fprintf(ENA, 'TRIG:SING;*OPC?');
    opComplete = fscanf(ENA, '%s');
    
    % Swap byte order on data query return.
    fprintf(ENA,'FORM:BORD SWAP');
    
    % Set Trace Data read or return format as binary bin block real 64-bit values
    fprintf(ENA, 'FORM:DATA REAL');
    
    % Select a trace to be read
    fprintf(ENA, 'CALC:PAR:SEL');
    
end
