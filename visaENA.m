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

        connectionTimer;        %connection timer to update the trace
        
        p1;                     %current spectrum plot
        p2;                     %current peak plot
        p3;                     %difference trace plot
        p4;                     %difference peaks plot

        dataToSave;             %data to save
        dataLogTimer;           %data log timer
        dataLogInterval;        %data log interval

        fitGaussNum;            %number of gaussian peaks to fit the curve, 4 by default
        fitGaussParameter;      %gaussian fit output parameters, arranged by center, width, center, width...
        fitGaussFlag;           %flag of the gaussian fminsearch fit, 1 means succeed
        fitGaussCurve;          %lines of the fitted gaussian peaks, the number of the lines is fitGaussNum
        fitGaussFrequency;      %frequency spectrum of Gauss fit analysis
        fitGaussData;           %data of Gauss fit
        c;


        useCursor;              %flag of using the cursor to select peaks
        leftCursor;             %left cursor on the figure and the lower boundary to selsct the peaks
        rightCursor;            %right cursor on the figure and the upper boundary to selsct the peaks
        savePath;
    end


    methods
        function obj = visaENA(visaAddress) %initialization with ENA visa address
            obj.ENA = setupTest(visaAddress); 
            obj.getInitialValue();
            obj.leftCursor = obj.Frequency(1);
            obj.rightCursor = obj.Frequency(end);
           
            obj.fitGaussNum = 4;
            obj.useCursor = false;

            obj.connectionTimer = timer;
            obj.dataLogTimer = timer;
            obj.dataLogInterval=0.1;
            obj.connectionTimerSet();
            obj.dataLogSet();
            
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
            obj.iniFrequency = obj.iniFrequency/1E6;
            obj.Frequency = obj.iniFrequency;
            obj.Data = obj.iniData;
            [obj.iniPks, obj.iniLocs] = obj.valleys(obj.iniData, obj.iniFrequency);
        end

        function getInitialValue1(obj)  %get and setup the initial ENA spectrum
            [obj.iniFrequency1, obj.iniData1] = getTraceData(obj.ENA, obj.dataQueryType);
            obj.iniFrequency1 = obj.iniFrequency1/1E6;
            obj.Frequency = obj.iniFrequency1;
            obj.Data = obj.iniData1;
            [obj.iniPks1, obj.iniLocs1] = obj.valleys(obj.iniData1, obj.iniFrequency1);
        end

        function getInitialValue2(obj)  %get and setup the initial ENA spectrum
            [obj.iniFrequency2, obj.iniData2] = getTraceData(obj.ENA, obj.dataQueryType);
            obj.iniFrequency2 = obj.iniFrequency2/1E6;
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

        function showTrace(obj, axs) %plot the current trace figure;
            cla(axs);
            obj.p1 = plot(axs ,obj.Frequency, obj.Data);
            hold(axs, 'on');
            obj.p2 = plot(axs ,obj.iniLocs, obj.iniPks, 'o');
        end

        function showDifference(obj, axs) %plot the differential trace;
            cla(axs);
            obj.p3 = plot(axs, obj.Frequency, obj.traceDifference);
            hold(axs, 'on');
            obj.p4 = plot(axs, obj.locsDiff, obj.pksDiff, 'o');
        end

        function slideChange(obj, changingValue)

        end

        function initShow(obj)
            fig1 = figure;
            obj.showTrace(fig1);
            fig2 = figure;
            obj.showDifference(fig2);
        end

        function updateData(obj)
            [tmp, obj.Data] = getTraceData(obj.ENA, obj.dataQueryType);
            obj.Frequency = tmp/1E6;
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

        function connection(obj)
            try
                obj.updateTrace;
            catch
                warning('Get Trace Error');
            end
        end

        function startConnection(obj)
            start(obj.connectionTimer);
        end

        function stopConnection(obj)
            stop(obj.connectionTimer);
        end

        function connectionTimerSet(obj)
            obj.connectionTimer.ExecutionMode = 'fixedRate';
            obj.connectionTimer.Period = obj.dataLogInterval;
            obj.connectionTimer.TimerFcn = @(~,~)obj.LogData();
        end
                      

        function fitGaussFun(obj)
            centerGuess = sort((obj.rightCursor-obj.leftCursor)*rand(obj.fitGaussNum, 1)+obj.leftCursor);
            widthGuess = (obj.rightCursor-obj.leftCursor)/obj.fitGaussNum * rand(obj.fitGaussNum, 1);
            initialGuesses = [centerGuess, widthGuess];
            startingGuesses = reshape(initialGuesses', 1, []);
            [~,leftIdx] = min(abs(obj.Frequency-obj.leftCursor));
            [~,rightIdx] = min(abs(obj.Frequency-obj.rightCursor));
            
            obj.fitGaussFrequency = obj.Frequency(leftIdx:rightIdx);
            obj.fitGaussData = -obj.Data(leftIdx:rightIdx);

            tFit = reshape(obj.fitGaussFrequency, 1, []);
            y = reshape(obj.fitGaussData, 1, []);
            
            % Perform an iterative fit using the FMINSEARCH function to optimize the height, width and center of the multiple Gaussians.
            options = optimset;  % Determines how close the model must fit the data
            options.TolFun = 1e-4;
            options.TolX = 1e-4;
            options.MaxFunEvals = 10^12;
            options.MaxIter = 100000;
            warning off;
            [obj.fitGaussParameter, fval, obj.fitGaussFlag, output] = fminsearch(@(lambda)(fitgauss(lambda, tFit, y, obj)), startingGuesses, options);

        end

        function plotFitGauss(obj, axs)
            cla(axs);
            centers = obj.fitGaussParameter(1:2:end);
            widths = obj.fitGaussParameter(2:2:end);
            legendStrings = cell(obj.fitGaussNum, 1);
            for i = 1:obj.fitGaussNum
                thisEstimatedCurve = - obj.c(i) .* gaussian(obj.fitGaussFrequency, centers(i), widths(i));
                plot(axs, obj.Frequency, thisEstimatedCurve, '-', 'LineWidth', 2);
                hold(axs, 'on');
                legendStrings{i} = sprintf('Gaussian Fit Curve %d', i);
            end
            plot(axs, obj.fitGaussFrequency, obj.fitGaussData);
            hold(axs, 'on');
            legendStrings{end+1} = sprintf('Raw Spectrum within %f to %f MHz', obj.leftCursor, obj.rightCursor);
            legend(legendStrings);
            drawnow;
        end

        function theError = fitgauss(lambda, t, y, obj)
        % Fitting function for multiple overlapping Gaussians
        % Author: T. C. O'Haver, 2006
	        A = zeros(length(t), round(length(lambda) / 2));
	        for j = 1 : length(lambda) / 2
		        A(:,j) = gaussian(t, lambda(2 * j - 1), lambda(2 * j))';
	        end
	        
	        obj.c = A \ y';
	        z = A * obj.c;
	        theError = norm(z - y');
	        
	        % Penalty so that heights don't become negative.
	        if sum(obj.c < 0) > 0
		        theError = theError + 1000000;
            end
        end

        function SaveData(obj)
            tmp = obj.dataToSave;
            if ~exist(fileparts(obj.savePath), 'dir')
                % 如果路径不存在，创建该路径
                mkdir(fileparts(obj.savePath));
            end
            save(obj.savePath, '-struct', 'tmp');
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
            if obj.useCursor
                indicesLocs = obj.Locs>=obj.leftCursor & obj.Locs<=obj.rightCursor;
                obj.dataToSave.Pks{end+1}=obj.Pks(indicesLocs);
                obj.dataToSave.Locs{end+1}=obj.Locs(indicesLocs);
                indicesDiff = obj.locsDiff>=obj.leftCursor & obj.locsDiff <= obj.rightCursor;
                obj.dataToSave.locsDiff{end+1}=obj.locsDiff(indicesDiff);
                obj.dataToSave.pksDiff{end+1}=obj.pksDiff(indicesDiff);
            else
                obj.dataToSave.Pks{end+1}=obj.Pks;
                obj.dataToSave.Locs{end+1}=obj.Locs;
                obj.dataToSave.locsDiff{end+1}=obj.locsDiff;
                obj.dataToSave.pksDiff{end+1}=obj.pksDiff;

            end
            obj.dataToSave.timeInterval = obj.dataLogInterval;

            % obj.dataToSave.Frequency{end+1} = obj.Frequency;
            % obj.dataToSave.Data{end+1} = obj.Data;
            % obj.dataToSave.traceDifference{end+1}=obj.traceDifference;
        end

        function dataLogSet(obj)
            obj.dataLogTimer.ExecutionMode = 'fixedRate';
            obj.dataLogTimer.Period = obj.dataLogInterval;
            obj.dataLogTimer.TimerFcn = @(~,~)obj.LogData();
        end

        function dataLogStart(obj)
            start(obj.dataLogTimer);
        end

        function dataLogStop(obj)
            stop(obj.dataLogTimer);
        end

    end
end

function g = gaussian(x, peakPosition, width)
%  gaussian(x,pos,wid) = gaussian peak centered on pos, half-width=wid
%  x may be scalar, vector, or matrix, pos and wid both scalar
%  T. C. O'Haver, 1988
% Examples: gaussian([0 1 2],1,2) gives result [0.5000    1.0000    0.5000]
% plot(gaussian([1:100],50,20)) displays gaussian band centered at 50 with width 20.
g = exp(-((x - peakPosition) ./ (0.60056120439323 .* width)) .^ 2);
end % of gaussian()
