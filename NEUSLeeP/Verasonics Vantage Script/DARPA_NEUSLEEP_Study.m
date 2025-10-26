% File name SetUpHIFUsystem.m:
%
% This file shows how to correctly program the HIFU system in the SetUp script.
% Compared with regular imaging script, comment lines with the prefix HIFU,
% identify the changes added to allow the script to exercise a TPC Profile 5
% HIFU transmit-only event. No image is created.
%
% Note: This script should be executed without connecting any transducer.
% It's mainly used for testing the communication with the external power
% supply for HIFU system.
%
% Last update 08/12/2020

clear all

%%
SysConfig = hwConfigCheck(1);

% Define system parameters.
Resource.Parameters.numTransmit = 8;      % number of transmit channels.
Resource.Parameters.numRcvChannels = Resource.Parameters.numTransmit;   % number of receive channels.
Resource.Parameters.speedOfSound = 1540;    % set speed of sound in m/sec before calling computeTrans
if contains(SysConfig.UTAname, 'UTA 128-LEMO')
    Resource.Parameters.Connector = [1];
else
    Resource.Parameters.Connector = 1;
end
Resource.Parameters.verbose = 2;
Resource.Parameters.initializeOnly = 0;
Resource.Parameters.fakeScanhead = 1;
Resource.Parameters.simulateMode = 0;
%  Resource.Parameters.simulateMode = 1 forces simulate mode, even if hardware is present.
%  Resource.Parameters.simulateMode = 2 stops sequence and processes RcvData continuously.

% HIFU % The Resource.HIFU.externalHifuPwr parameter must be specified in a
% script using TPC Profile 5 with the HIFU option, to inform the system
% that the script intends to use the external power supply.  This is also
% to make sure that the script was explicitly written by the user for this
% purpose, and to prevent a script intended only for an Extended Transmit
% system from accidentally being used on the HIFU system.
Resource.HIFU.externalHifuPwr = 1;

% HIFU % The string value assigned to the variable below is used to set the
% port ID for the virtual serial port used to control the external HIFU
% power supply.  The port ID was assigned by the Windows OS when it
% installed the SW driver for the power supply; the value assigned here may
% have to be modified to match.  To find the value to use, open the Windows
% Device Manager and select the serial/ COM port heading.  If you have
% installed the driver for the external power supply, and it is connected
% to the host computer and turned on, you should see it listed along with
% the COM port ID number assigned to it.
Resource.HIFU.extPwrComPortID = 'COM3';

% HIFU % The system now supports two different commercial power supplies
% for HIFU: the AIM-TTI model QPX600DP and the Sorensen model XG40-38.
% These power supplies use different command formats for remote control
% through the USB-based virtual serial port, and so the power supply
% control funtion must be told which supply is present.  This is done in
% the setup script through the field Resource.HIFU.psType, which must be
% set to a string value of either 'QPX600DP' or 'XG40-38'.  If this field
% is not specified, a default value of 'QPX600DP' will be used.
Resource.HIFU.psType = 'QPX600DP'; % set to 'QPX600DP' to match supply being used

% Fake transducer definition because the transducer should not be connected
if isequal(1,getConnectorInfo) % the default return value will be 1 if the transducer is connected
    warning('Transducer is connected, please remove the transducer for testing the external power.');
end
Trans.name = 'custom';      % use custom to prevent the id check
Trans.units = 'mm';
Trans.frequency = 0.65;                            % nominal frequency in MHz
Trans.Bandwidth = [0.90, 1.10] * Trans.frequency;  % 60% bandwidth default value
Trans.type = 3;                                 % 1-assuming curved/ring array (the array type doesn't matter if focal law and image Recon calculated by users).
Trans.numelements = Resource.Parameters.numTransmit;
%Trans.connType = SysConfig.UTAtype(2);
Trans.connType = 11;
Trans.id = hex2dec('0000'); % Dummy ID to be used with the 'fake scanhead' feature

% Define element dimensions
Trans.ElementPos(1,:) = [5.35 10.07 (5.35+10.07)/2 0 0];
Trans.ElementPos(2,:) = [10.72 15.42 (10.72+15.42)/2 0 0];
Trans.ElementPos(3,:) = [16.07 20.78 (16.07+20.78)/2 0 0];
Trans.ElementPos(4,:) = [21.43 26.14 (21.43+26.14)/2 0 0];
Trans.ElementPos(5,:) = [26.79 31.49 (26.79+31.49)/2 0 0];
Trans.ElementPos(6,:) = [32.15 36.86 (32.15+36.86)/2 0 0];
Trans.ElementPos(7,:) = [37.51 42.21 (37.51+42.21)/2 0 0];
Trans.ElementPos(8,:) = [42.86 47.57 (42.86+47.57)/2 0 0];



Trans.ElementSens = ones(1,101);
Trans.spacing = 0.65e-3/(Resource.Parameters.speedOfSound/650e3);
%Trans.radius = 0;
Trans.lensCorrection = 0;                           % this value  in wavelength will be used in image reconstruction to correct the errors of pathlength caused by acoustic lens

Trans.impedance = 50;                               % this value will be used for TXEventCheck, a self-protection utility function preventing system from overload.
%Trans.impedance = 10000;


Trans.maxHighVoltage = 96;                          % set the max voltage from pulser, preventing damage of a probe and the system
TPC(5).maxHighVoltage = 100;

% Initialize the P5 monitor limit values
P5HVmin = 0;
P5HVmax = 0;

%% Define P.data Structure
P.startDepth = 0;
P.endDepth = 160;   % Acquisition depth in wavelengths

na = 100;      % Number of angles
if na > 1
    dtheta = (60*pi/180)/(na-1);
    startAngle = -60*pi/180/2;  % set dtheta to range over +/- 30 degrees.
else
    dtheta = 0;
    startAngle = 0;
end

%% Setup Resources and TW
% Set up Resources.
Resource.RcvBuffer(1).datatype = 'int16';
Resource.RcvBuffer(1).rowsPerFrame = 4096;
Resource.RcvBuffer(1).colsPerFrame = Resource.Parameters.numRcvChannels;  % this should match number of receive channels
Resource.RcvBuffer(1).numFrames = 1;

% Specify TW structure array.
TW.type = 'parametric';

% Scan parameter
%TW.Parameters = [Trans.frequency,0.9,10,1]; 

% Stimulation parameters
TW.Parameters = [Trans.frequency,0.65,2*3250,1]; % 10Hz

% Push % A separate transmit waveform, TW(2), is defined for the Push
% transmit. This waveform will be used with TPC profile 5 and the Extended
% Burst transmit power supply, allowing high-power bursts of up to several
% milliseconds duration.
bdur = 0.1; % initial burst duration in msec
pushFreq = 4; % profile 5 push burst frequency MHz
numBursts = 1; % number of P5 transmit bursts- set to 1, 2, or 3

TW.equalize = 1;

%% Define TX Delays
focal_depth = 0;

% Specify TX structure array.
TX = repmat(struct('waveform', 1, ...
                   'Origin', [0.0,0.0,0.0], ...
                   'focus', 1, ...
                   'Steer', [0.0,0.0], ...
                   'Apod', ones(1,Resource.Parameters.numTransmit), ...  % set TX.Apod for  elements
                   'Delay', zeros(1,Resource.Parameters.numTransmit)), 1, na);

% - Set event specific TX attributes.
for n = 1:na   % na transmit events
    %TX(n).Steer = [(startAngle+(n-1)*dtheta),0.0];
    TX(n).focus = focal_depth+n;
    TX(n).Delay = computeTXDelays(TX(n));
end

%Plot Delay Profiles
%figure
for n = 1:na
    %plot(-TX(n).Delay); hold on
    DTX(n,:) = abs(TX(n).Delay);
end
%xlabel('Element #')
%ylabel('Delay Time (us)');
%title('Annular Array Delay Profiles')
%legend

%% Select TX Profile
n = 58;

TX_DelayProfile = TX(n).Delay;

% Specify TX structure array.
TX = repmat(struct('waveform', 1, ...
                   'Origin', [0.0,0.0,0.0], ...
                   'focus', focal_depth+n, ...
                   'Steer', [0.0,0.0], ...
                   'Apod', ones(1,Resource.Parameters.numTransmit), ...  % set TX.Apod for  elements
                   'Delay', TX_DelayProfile), 1, 1);



%%
% Specify SeqControl structure arrays.
%  - Jump back to start.
SeqControl(1).command = 'triggerIn';
SeqControl(1).condition = 'Trigger_1_Rising';
SeqControl(1).argument = 0;
SeqControl(2).command = 'jump';
SeqControl(2).argument = 1;
%SeqControl(3).command = 'timeToNextAcq';  % time between frames
%SeqControl(3).argument = 100000;  % 100 ms
SeqControl(3).command = 'triggerOut';



nsc = 4; % nsc is count of SeqControl objects

n = 1; % n is count of Events

% Initial TPC profile 5
Event(n).info = 'select TPC profile 5';
Event(n).tx = 0;
Event(n).rcv = 0;
Event(n).recon = 0;
Event(n).process = 0;
Event(n).seqControl = nsc; % set TPC profile command.
n = n+1;
SeqControl(nsc).command = 'setTPCProfile';
SeqControl(nsc).argument = 5;
SeqControl(nsc).condition = 'immediate';
nsc = nsc + 1;

% Send HIFU pulse
for i = 1:Resource.RcvBuffer(1).numFrames
    Event(n).info = 'HIFU pulse';
    Event(n).tx = 1;
    Event(n).rcv = 0;
    Event(n).recon = 0;
    Event(n).process = 0;
    Event(n).seqControl = [1,2,3];
    n = n+1;
end

Event(n).info = 'Jump back to first event';
Event(n).tx = 0;
Event(n).rcv = 0;
Event(n).recon = 0;
Event(n).process = 0;
Event(n).seqControl = 1;

% User specified UI Control Elements

import vsv.seq.uicontrol.VsSliderControl


% - Range Change


% P5 HV monitor max voltage limit
UI(1).Control = VsSliderControl('LocationCode','UserB5',...
    'Label','P5 Max Limit',...
    'SliderMinMaxVal',[0, Trans.maxHighVoltage, P5HVmax],...
    'SliderStep',[0.01,0.05],'ValueFormat','%3.1f',...
    'Callback',@P5MaxCallback);

% P5 HV monitor min voltage limit
UI(2).Control = VsSliderControl('LocationCode','UserB4',...
    'Label','P5 Min Limit',...
    'SliderMinMaxVal',[0, Trans.maxHighVoltage, P5HVmin],...
    'SliderStep',[0.01,0.05],'ValueFormat','%3.1f',...
    'Callback',@P5MinCallback);

% burst duration control
UI(3).Control = VsSliderControl('LocationCode','UserC3',...
    'Label','P5 Bdur msec','SliderMinMaxVal',[0, 1, bdur],...
    'SliderStep',[0.1,0.2],'ValueFormat','%3.2f',...
    'Callback',@BdurCallback);

% Num P5 bursts control
UI(4).Control = VsSliderControl('LocationCode','UserC2',...
    'Label','num P5 Bursts','SliderMinMaxVal',[1, 3, numBursts],...
    'SliderStep',[0.5,0.5],'ValueFormat','%3.0f',...
    'Callback',@numBurstCallback);

% Save all the structures to a .mat file.
save('MatFiles/Scan_Acoustic_Field_Multi_Annular');

return


%% Automatic VSX Execution:
% Uncomment the following line to automatically run VSX every time you run
% this SetUp script (note that if VSX finds the variable 'filename' in the
% Matlab workspace, it will load and run that file instead of prompting the
% user for the file to be used):

filename = 'DARPA_NEUSLEEP_StudyA_10Hz';  VSX;


%% **** Callback routines used by UIControls (UI) ****

function SensCutoffCallback(~, ~, UIValue)
    ReconL = evalin('base', 'Recon');
    for i = 1:size(ReconL,2)
        ReconL(i).senscutoff = UIValue;
    end
    assignin('base','Recon',ReconL);
    Control = evalin('base','Control');
    Control.Command = 'update&Run';
    Control.Parameters = {'Recon'};
    assignin('base','Control', Control);
end

function RangeChangeCallback(hObject, ~, UIValue)
    simMode = evalin('base','Resource.Parameters.simulateMode');
    % No range change if in simulate mode 2.
    if simMode == 2
        set(hObject,'Value',evalin('base','P.endDepth'));
        return
    end
    Trans = evalin('base','Trans');
    Resource = evalin('base','Resource');
    scaleToWvl = Trans.frequency/(Resource.Parameters.speedOfSound/1000);

    P = evalin('base','P');
    P.endDepth = UIValue;
    if isfield(Resource.DisplayWindow(1),'AxesUnits')&&~isempty(Resource.DisplayWindow(1).AxesUnits)
        if strcmp(Resource.DisplayWindow(1).AxesUnits,'mm')
            P.endDepth = UIValue*scaleToWvl;
        end
    end
    assignin('base','P',P);

    evalin('base','PData(1).Size(1) = ceil((P.endDepth-P.startDepth)/PData(1).PDelta(3));');
    evalin('base','PData(1).Region = computeRegions(PData(1));');
    evalin('base','Resource.DisplayWindow(1).Position(4) = ceil(PData(1).Size(1)*PData(1).PDelta(3)/Resource.DisplayWindow(1).pdelta);');
    Receive = evalin('base', 'Receive');
    maxAcqLength = ceil(sqrt(P.endDepth^2 + ((Trans.numelements-1)*Trans.spacing)^2));
    for i = 1:size(Receive,2)
        Receive(i).endDepth = maxAcqLength;
    end
    assignin('base','Receive',Receive);
    evalin('base','TGC.rangeMax = P.endDepth;');
    evalin('base','TGC.Waveform = computeTGCWaveform(TGC);');
    Control = evalin('base','Control');
    Control.Command = 'update&Run';
    Control.Parameters = {'PData','InterBuffer','ImageBuffer','DisplayWindow','Receive','TGC','Recon'};
    assignin('base','Control', Control);
    assignin('base', 'action', 'displayChange');
end

function P5MaxCallback(~, ~, UIValue)
    P5HVmax = UIValue;
    assignin('base', 'P5HVmax', P5HVmax);
    P5HVmin = evalin('base', 'P5HVmin');
    % call the function to set new limit values
    rc = setProfile5VoltageLimits(P5HVmin, P5HVmax);
    if ~strcmp(rc, 'Success')
        fprintf(2, ['Error from setProfile5VoltageLimits: ', rc, ' \n'])
    end
end

function P5MinCallback(~, ~, UIValue)
    P5HVmin = UIValue;
    assignin('base', 'P5HVmin', P5HVmin);
    P5HVmax = evalin('base', 'P5HVmax');
    % call the function to set new limit values
    rc = setProfile5VoltageLimits(P5HVmin, P5HVmax);
    if ~strcmp(rc, 'Success')
        fprintf(2, ['Error from setProfile5VoltageLimits: ', rc, ' \n'])
    end
end

function BdurCallback(~, ~, UIValue)
    bdur = UIValue;
    assignin('base', 'bdur', bdur);  % Burst duration in milliseconds
    TW = evalin('base', 'TW');
    TW(2).Parameters(3) = 2000*bdur*TW(2).Parameters(1); % scale bdur * freq to number of halfcycles
    assignin('base', 'TW', TW);
    Control = evalin('base','Control');
    Control.Command = 'update&Run';
    Control.Parameters = {'TW'};
    assignin('base','Control', Control);
end

function numBurstCallback(~, ~, UIValue)
    numBursts = round(UIValue);
    assignin('base', 'numBursts', numBursts);
    Event = evalin('base', 'Event');
    firstPushEvent = evalin('base', 'firstPushEvent');
    switch numBursts
        case 1
            Event(firstPushEvent).tx = 0; % disable first push
            Event(firstPushEvent + 1).tx = 0; % disable second push
        case 2
            Event(firstPushEvent).tx = 0; % enable first push
            Event(firstPushEvent + 1).tx = 2; % disable second push
        case 3
            Event(firstPushEvent).tx = 2; % enable first push
            Event(firstPushEvent + 1).tx = 2; % enable second push
    end
    assignin('base', 'Event', Event);
    Control = evalin('base','Control');
    Control.Command = 'update&Run';
    Control.Parameters = {'Event'};
    assignin('base','Control', Control);
end


