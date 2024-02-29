function [frequency, Data] = getTraceData(ENA, dataQueryType)
    
    fprintf(ENA, dataQueryType);
    % Read return data as binary bin block real 64-bit values. 
    cData = binblockread(ENA, 'float64');
    Data = cData(1:2:end);
    % Binblock read has a 'hanging line feed' that must be read and disposed
    fscanf(ENA, '%c');
    
    % Read the stimulus values
    fprintf(ENA,'SENSE:FREQ:DATA?');
    frequency = binblockread(ENA,'float64');
    % Binblock read has a 'hanging line feed' that must be read and disposed
    fscanf(ENA, '%c');

end
