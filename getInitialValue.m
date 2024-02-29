function [pks, locs, frequency, cData] = getInitialValue(ENA, dataQueryType)
    [frequency, cData] = getTraceData(ENA, dataQueryType);
    [pks, locs] = findpeaks(cData(1:2,end), frequency, 'MinPeakProminence',)



end