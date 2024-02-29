classdef visaENA < handle
    properties
        ENA;                    %visa ENA object to communicate with
        dataQueryType = 'CALC:DATA:FDATA?';
        
        MinPeakProminance = 0.01;       %prominance to decide the peak of the spectrum
        MinPeakHeight = 0;              %minium peak height
        Threshold = 0;                  %minium height difference
        MinPeakWidth = 0;               %minium peak width
        
        iniFrequency;           %initial Frequency of the spectrum
        iniData;                %initial Data of the spectrum
        iniPks;                 %initial peaks of the spectrum
        iniLocs;                %initial locations of the peaks of the 

        iniFrequency1;           %initial Frequency of the spectrum
        iniData1;                %initial Data of the spectrum
        iniPks1;                 %initial peaks of the spectrum
        iniLocs1;                %initial locations of the peaks of the 
        
        iniFrequency2;           %initial Frequency of the spectrum
        iniData2;                %initial Data of the spectrum
        iniPks2;                 %initial peaks of the spectrum
        iniLocs2;                %initial locations of the peaks of the 


        Frequency;              %current Frequency of the spectrum
        Data;                   %current Data of the spectrum
        Pks;                    %peaks of the current spectrum
        Locs;                   %Location of the peaks of the current spectrum
        traceDifference;        %difference of the current Data and initial Data
        pksDiff;                %peaks of the difference trace
        locsDiff;               %locations of the difference trace
        
        minDeltPara;            %minium peak decide parameter
        peaks;                  %array of peaks of trace
        peaksTemp;              %temp peaks
        devicePks;              %array of sorted peakPoint 
        peakTrace;              %follow the peak variance trace while measuring
        diffPeakTrace;          %follow the peak variance of differential spectrum while measuring
        
        p1;                     %current spectrum plot
        p2;                     %current peak plot
        p3;                     %difference trace plot
        p4;                     %difference peaks plot
    end


    methods
        function obj = visaENA(visaAddress) %initialization with ENA visa address
            obj.ENA = setupTest(visaAddress); 
            obj.getInitialValue();
            obj.updateData();
            %obj.initShow();
        end

        function delete(obj)
            if ~isempty(obj.ENA)
                closeTest(obj.ENA);
                fprintf("ENA deleted");
            end
        end

        function getInitialValue(obj)  %get and setup the initial ENA spectrum
            [obj.iniFrequency, obj.iniData] = getTraceData(obj.ENA, obj.dataQueryType);
            obj.Frequency = obj.iniFrequency;
            obj.Data = obj.iniData;
            [obj.iniPks, obj.iniLocs] = obj.valleys(obj.iniData, obj.iniFrequency);
        end

        function getInitialValue1(obj)  %get and setup the initial ENA spectrum
            [obj.iniFrequency1, obj.iniData1] = getTraceData(obj.ENA, obj.dataQueryType);
            obj.Frequency = obj.iniFrequency1;
            obj.Data = obj.iniData1;
            [obj.iniPks1, obj.iniLocs1] = obj.valleys(obj.iniData1, obj.iniFrequency1);
        end

        function getInitialValue2(obj)  %get and setup the initial ENA spectrum
            [obj.iniFrequency2, obj.iniData2] = getTraceData(obj.ENA, obj.dataQueryType);
            obj.Frequency = obj.iniFrequency2;
            obj.Data = obj.iniData2;
            [obj.iniPks2, obj.iniLocs2] = obj.valleys(obj.iniData2, obj.iniFrequency2);
        end

        function setInitialValue1(obj)
            obj.iniFrequency = obj.iniFrequency1;
            obj.iniData = obj.iniData1;
            obj.Frequency = obj.iniFrequency;
            obj.Data = obj.iniData;
            [obj.iniPks, obj.iniLocs] = obj.valleys(obj.iniData, obj.iniFrequency);
        end

        function setInitialValue2(obj)
            obj.iniFrequency = obj.iniFrequency2;
            obj.iniData = obj.iniData2;
            obj.Frequency = obj.iniFrequency;
            obj.Data = obj.iniData;
            [obj.iniPks, obj.iniLocs] = obj.valleys(obj.iniData, obj.iniFrequency);
        end

        function [pks, locs] = valleys(obj, y, x)      %find the vally peaks of the ENA spectrum
            [npks,locs] = findpeaks(-y,x, "MinPeakProminence", obj.MinPeakProminance, "MinPeakHeight",obj.MinPeakHeight, ...
                "Threshold", obj.Threshold, "MinPeakWidth", obj.MinPeakWidth);
            pks = -npks;
        end

        function showTrace(obj, fig) %plot the current trace figure;
            obj.p1 = plot(fig ,obj.Frequency, obj.Data);
            hold(fig, 'on');
            obj.p2 = plot(fig ,obj.iniLocs, obj.iniPks, 'o');
        end

        function showDifference(obj,fig) %plot the differential trace;
            obj.p3 = plot(fig, obj.Frequency, obj.traceDifference);
            hold(fig, 'on');
            obj.p4 = plot(fig, obj.locsDiff, obj.pksDiff, 'o');
        end

        function initShow(obj)
            fig1 = figure;
            obj.showTrace(fig1);
            fig2 = figure;
            obj.showDifference(fig2);
        end

        function updateData(obj)
            [obj.Frequency, obj.Data] = getTraceData(obj.ENA, obj.dataQueryType);
            obj.traceDifference = obj.Data - obj.iniData;
            [obj.Pks, obj.Locs] = obj.valleys(obj.Data, obj.Frequency);
            [obj.pksDiff, obj.locsDiff] = obj.valleys(obj.traceDifference, obj.Frequency);
        end

        function updateTrace(obj)    %update the figure;
            obj.updateData;
            set(obj.p1, 'XData', obj.Frequency, 'YData', obj.Data);
            set(obj.p2, 'XData', obj.Locs ,'YData', obj.Pks);
            set(obj.p3, 'XData', obj.Frequency, 'YData', obj.traceDifference);
            set(obj.p4, 'XData', obj.locsDiff, 'YData', obj.pksDiff);
            drawnow;
        end
        
        function labelPks(obj)
            %label the peaks of trace, decided by the distance 
            % delta between a peak and former peaks. For example, seperate
            % two peaks A and B acquired by finding peaks in the former
            % trace, and peak B moved left to B' in next acquired trace,
            % and the distance between A and B is AB, B and B' is deltB,
            % then deltB shold be the smallest of all the distance between
            % B' and all other peaks. However, if B moved across A, deltB
            % should be nearer to the average deltB over time comparaed to
            % deltA, and thus deciding the peak is still B other than A. If
            % a new peak C showed up, the distance of C to any other peaks
            % shold be larger than a threshold, and thus a new peak is
            % included.
            for peak = obj.peaksTemp
                delt = abs([obj.peaks.locs] - peak.locs);
                [minDelt, I] = min(delt);
                if minDelt > obj.minDeltPara
                    peak.label = size(obj.peaks, 2) + 1;
                    obj.peaks = [obj.peaks, peak];
                elseif minDelt <= obj.minDeltPara
                    if peakdissappered && disapperedpeakdistance<somethreshold
                        %set the disappered peak disappered
                        %

                    end
                    peak.label = obj.peaks(I).label;
                    obj.peaks(I) = peak;
                end
            end
        end

        function SaveData(obj)
            FN = datestr(datetime, 'yyyy-mm-dd-HH-MM-SS');
            CurrentData = {};
            CurrentData.Frequency = obj.Frequency;
            CurrentData.Locs = obj.Locs;
            CurrentData.Pks = obj.Pks;
            CurrentData.Data = obj.Data;
            CurrentData.traceDifference = obj.traceDifference;
            CurrentData.locsDiff = obj.locsDiff;
            CurrentData.pksDiff = obj.pksDiff;

            save(strcat('Data\', FN), '-struct', 'CurrentData');
        end

    end

end