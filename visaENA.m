%here test
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

        dataToSave;             %data to save
        savePath;
    end


    methods
        function obj = visaENA(visaAddress) %initialization with ENA visa address
            obj.ENA = setupTest(visaAddress); 
            obj.getInitialValue();
            obj.updateData();
            obj.initDataToSave();
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
            try
                set(obj.p1, 'XData', obj.Frequency, 'YData', obj.Data);
            catch
                obj.p1 = plot(fig ,obj.Frequency, obj.Data);
            end

            try
                set(obj.p2, 'XData', obj.Locs ,'YData', obj.Pks);
            catch 
                obj.p2 = plot(fig ,obj.iniLocs, obj.iniPks, 'o');
            end

            try
                set(obj.p3, 'XData', obj.Frequency, 'YData', obj.traceDifference);
            catch
                obj.p3 = plot(fig, obj.Frequency, obj.traceDifference);
            end

            try
                set(obj.p4, 'XData', obj.locsDiff, 'YData', obj.pksDiff);
            catch
                obj.p4 = plot(fig, obj.locsDiff, obj.pksDiff, 'o');
            end
            drawnow;
        end

        function SaveData(obj)
            FN = datestr(datetime, 'yyyy-mm-dd-HH-MM-SS');
            save(strcat(obj.savePath, '\', FN), '-struct', 'obj.dataToSave');
        end

        function initDataToSave(obj)
            obj.dataToSave.Pks={};
            obj.dataToSave.Locs={};
            obj.dataToSave.locsDiff = {};
            obj.dataToSave.pksDiff = {};
            obj.dataToSave.Frequency = {};
            obj.dataToSave.Data = {};
            obj.dataToSave.traceDifference={};
        end
        
        function LogData(obj)
            obj.dataToSave.Pks{end+1}=obj.Pks;
            obj.dataToSave.Locs{end+1}=obj.Pks;
            obj.dataToSave.locsDiff{end+1}=obj.locsDiff;
            obj.dataToSave.pksDiff{end+1}=obj.pksDiff;
            obj.dataToSave.Frequency{end+1} = obj.Frequency;
            obj.dataToSave.Data{end+1} = obj.Data;
            obj.dataToSave.traceDifference{end+1}=obj.traceDifference;
        end

    end

end