function closeTest(ENA)
    % Return data transfer format back to ASCII string format
    fprintf(ENA, 'FORM:DATA ASCII');
    
    % Return trigger source to internal and free running
    fprintf(ENA, 'TRIG:SOUR INT');
    
    % As a last step query the ENA error queue a final time and ensure no errors have
    % occurred since initiation of program. 
    fprintf(ENA, 'SYST:ERR?');
    errIdentifyStop = fscanf(ENA, '%c');
    fprintf(strcat('\nThe final error query results string is:\t',errIdentifyStop))
    
    % Close session connection
    fclose(ENA);
    delete(ENA);
    clear ENA;

end