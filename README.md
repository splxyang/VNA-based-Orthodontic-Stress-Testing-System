# VNA-based-Orthodontic-Stress-Testing-System
Using MATLAB with the VISA interface to control the VNA instrument for collecting S-parameter spectra, calculating spectral differences, identifying the positions of spectral valleys, and annotating them.

1. System requirements
The application is built on MATLAB 2023b and run on windows, and requires Keysight IO Libraries Suite to connect the VNA.

2. Installation guide
The application could be run on the PC with MATLAB insltalled by opening the "LCOSS.mlapp" file, or could be installed with the released file "LCOSSSteup.exe", it might take a while to download the MATLAB runtime form the web if not installed.

3. Demo
We offer a sample data './sample/sampleData.mat' recorded during the experiment, the data inlcudes a S11 spectrum with one local-minimum of the sensor, you could tell the resonant frequency of the sensor on the figure and view the slow drift of the signal. 

4. Instructions for use
While installed on a computer, you could connect the computer with a Keysight VNA. The Keysight IO Library Suite is needed to find the instrument via VISA interface. The address of the instrument could be found with the Keysight Connection Expert.
By clicking the 'Connect' button, the application would fetch the data from the VNA continuely, you could pause/resume the measurement by clicking the 'Pause' button.
The initial trace of the spectrum is recorded at the first trial, and you can set the inital tarce by clicking the 'Get Inital Trace' button to calculate the diffrential trace.
To record the data, you can click the 'Start Data Log' button. If you want to record only part of the spectrum, you could tick the 'Cursor' box, and set the range you want. 
If you want to review the data you logged, you can click the 'Load Data' button.
The local minimums of the spectrum is calculated by the findpeaks function of MATLAB, you could set the parameters on the GUI.
The measured or loaded S11 spectrum could be used to fit with the Gaussian waves. Modify the number of Gaussian peaks, and click the 'Gaussian Fit' button. Due to randomness, the result may be not well fitted, you could re-click the button to find a better result.