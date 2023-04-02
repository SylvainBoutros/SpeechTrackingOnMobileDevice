sca;
close all;
clear;

rng('shuffle');
% Root to folder containing Code, Data folders
% This will need to be updated
matlabroot = '/PATH/TO/FOLDER/SpeechTrackingONMobileDevice/';

cd(matlabroot);
addpath(genpath('Codes'));
addpath(genpath('Data'));
% This should be fine
DataPath = [matlabroot '/Data/StimFiles/stimuliTables.mat'];
rampON = 0; % Change to 1 if needing to add a 10 msec ramp for audio
[practice_trials, experiment_trials] = genStims(DataPath, rampON);

% Repetitions and sample rate
kRepetition = 1;
fs = 16000; %hardcoded here, but you could read this from the audio files
%% Get participant information
prompt = {'ID Number:', 'Age:', 'Sex (m/f):', 'Handedness (L/R):', 'Course:', 'Instructor:', 'EEG (0/1):'};
dlg_title = 'Participant Information';
num_lines = 1;
deaultans = {'000', '18', 'M', 'R', 'Neuro1000', 'Tata', '0'};
answers = inputdlg(prompt, dlg_title, num_lines, deaultans);
participant = cleanup(answers);

%% Connect to NetStation if participant.egg == 1
% Depending on system might just remove this section if not using NetStation
NS_IP = '142.66.210.203'; % Change to reflect current NetStation IP address
if participant.eeg == 1  
    NetStation('Connect', NS_IP);
    NetStation('Synchronize');
    NetStation('StartRecording');
end

%% Setup Psychtoolbox screen
% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);
InitializePsychSound;
[kbID, ~] = GetKeyboardIndices;
Screen('Preference', 'SkipSyncTests', 1);

% Drawing the first screen
screenNumber = max(Screen('Screens'));
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);

[window, windowRect] = PsychImaging('OpenWindow', screenNumber, black);
ifi = Screen('GetFlipInterval', window);
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
[xCenter, yCenter] = RectCenter(windowRect);
fixCrossDimPix = 40;
xCoords = [-fixCrossDimPix, fixCrossDimPix, 0, 0];
yCoords = [0, 0, -fixCrossDimPix, fixCrossDimPix];
allCoords = [xCoords; yCoords];
lineWidthPix = 6;
Screen('TextSize', window, 20);
commandwindow;
% ***WARNING*** 
% The following command will block the keyboard input. If the program fails
% or abort, use the mouse to highligh ListenChar(0) right click and evaluate 
% to get access to you keyboard  
% ListenChar(2);
%% Define some instructions
instruction1 = ['In this experiment you will hear both music and speech. \n\n' ...
                'On music trials, your task is to rate the familiarity of the music from 1-5 (1 is least familiar, 5 most familiar) \n\n ' ...
                'On speech trials your task is to rate your understanding of the speech from 1-5. (1 is did not understand, 5 is fully understood)\n\n' ...
                'Press enter when you are ready to start some practice trials.'];

instruction2 = ['In this experiment you will hear both music and speech. \n\n' ...
                'On music trials, your task is to rate the familiarity of the music from 1-5 (1 is least familiar, 5 most familiar) \n\n ' ...
                'On speech trials your task is to rate your understanding of the speech from 1-5. (1 is did not understand, 5 is fully understood)\n\n' ...
                'Press enter when you are ready to start the experiment trials.'];

breakInstructions = ['Take a break\n\n' ...
                     'Press enter when you are ready to continue'];

thanksInstruction = ['Thank you for participating\n\n' ...
                     'Press a key to close this window'];

musicRating = 'Please rate the familiarity of the music from 1-5.';

speechRating = 'Please rate your understanding of the speech from 1-5.';

%% Display some instructions
DrawFormattedText(window, instruction1, 'center', 'center', white);
Screen('Flip', window);
KbStrokeWait;

%% Initialize the audio buffer
% Reference here: http://psychtoolbox.org/docs/PsychPortAudio-Open
% pahandle = PsychPortAudio(‘Open’ [, deviceid][, mode][, reqlatencyclass][, freq][, channels][, buffersize][, suggestedLatency][, selectchannels][, specialFlags=0]);
% To get which deviceid to use run: PsychPortAudio('GetDevices')
% This should output a structure with all the devices info
% Reference here: http://psychtoolbox.org/docs/PsychPortAudio-GetDevices
pahandle = PsychPortAudio('Open', 2, [], 0, fs, 1);

%% Start the practice trials here
% Could possibly omit this as we are not interested in pracice responses
practiceResponses = struct();

for i = 1:length(practice_trials)
    % Get the audio from the practice trials 
    audio = practice_trials(i).y;
    % Draw the cross
    Screen('DrawLines', window, allCoords, lineWidthPix, white, [xCenter, yCenter], 2);
    Screen('Flip', window);
    % Fill the buffer
    PsychPortAudio('FillBuffer', pahandle, audio');
    WaitSecs(1.5); % Good to wait so the audio doesn't start before buffer filled
    playTime = practice_trials(i).duration;
    % Start the audio
    PsychPortAudio('Start', pahandle, 1, 0, 1);
    WaitSecs(playTime);
    % Stop the audio
    PsychPortAudio('Stop', pahandle);
    WaitSecs(1.5);
    % Empty buffer
    PsychPortAudio('DeleteBuffer');
    % Display instruction depending on which type of stimuli was presented
    if isequal(practice_trials(i).type, "M")
        practice_number = GetEchoNumber(window, musicRating, xCenter, yCenter, white);
    else
        practie_number = GetEchoNumber(window, speechRating, xCenter, yCenter, white);
    end
    disp(practice_number);
    Screen('Flip', window);
    Screen('FillRect', window, black);
end


%% Display some instructions
DrawFormattedText(window, instruction2, 'center', 'center', white);
Screen('Flip', window);
KbStrokeWait;

%% Start the experiment trials

exp_responses = struct();

for i = 1:kRepetition
    % if kRepetition is > 1 should shuffle the whole experiment_trials structure
    % experiment_trials = experiment_trials(randperm(size(experiment_trials,1)), :);
%     experiment_trials = Shuffle(experiment_trials);

    for j = 1:length(experiment_trials)
        % Get the audio from the experiment trials
        audio = experiment_trials(j).y;
        event = experiment_trials(j).event;
        exp_responses(i, j).event = event;
        % Draw the cross
        Screen('DrawLines', window, allCoords, lineWidthPix, white, [xCenter, yCenter], 2);
        Screen('Flip', window);
        % Fill the buffer
        PsychPortAudio('FillBuffer', pahandle, audio');
        WaitSecs(1.5); % Good to wait so the audio doesn't start before buffer filled
        playTime = experiment_trials(j).duration;
        % Start the audio
        exp_responses(i, j).startTime = PsychPortAudio('Start', pahandle, 1, 0, 1);
        %%% SHOULD BE SENDING A STARTING EVENT HERE WITH `event` LABEL
        WaitSecs(playTime);
        % Stop the audio
        exp_responses(i, j).stopTime = PsychPortAudio('Stop', pahandle);
        %%% SHOULD BE SENDING A STOPING EVENT HERE WITH `event` LABEL
        WaitSecs(1.5);
        % Empty buffer
        PsychPortAudio('DeleteBuffer');
        % Collect timestamp of typing onset
        [~, exp_responses(i, j).startTyping] = KbCheck(kbID);
        %%% SHOULD BE SENDING A TYPING TIMESTAMP AND LABEL T0XX WHERE XX
        %%% REPRESENT TRIAL NUMBER
        % Display instruction depending on which type of stimuli was presented
        if isequal(experiment_trials(i).type, "M")
            exp_responses(i, j).ratings = GetEchoNumber(window, musicRating, xCenter-200, yCenter, white);
        else
            exp_responses(i, j).ratings = GetEchoNumber(window, speechRating, xCenter-200, yCenter, white);
        end

        exp_responses(i, j).stopTyping = Screen('Flip', window);
        Screen('FillRect', window, black);
        if participant.eeg == 1
            NetStation('Event', 'XXXX', exp_responses(i, j).startTime, playTime);
            NetStation('Event', 'XXXX', exp_responses(i, j).stopTime);
            NetStation('Event', 'T0XX', exp_responses(i, j).startTyping, exp_responses(i, j).stopTyping);
        end
    end
    disp('******** BREAK ********');
    DrawFormattedText(window, breakInstruction, 'center', 'center', white);
    Screen('Flip', window);
    KbStrokeWait;
end

% Thank participant
DrawFormattedText(window, thanksInstruction, 'center', 'center', white);
Screen('Flip', window);
KbStrokeWait;
Screen('FillRect', window, black);
Screen('Flip', window);

%% Saving and releasing all allocations
% ListenChar(0);
save(['Data/Subjects/subject' num2str(participant.id) '.mat'], "participant", "exp_responses");
Screen('CloseAll');
% Stop recording and disconnect from NetStation
% Same could remove this whole conditional statement if NS not used
if participant.eeg == 1
    NetStation('StopRecording');
    NetStation('Disconnect');
end
% Close pahandle 
PsychPortAudio('Close', pahandle);
