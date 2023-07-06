%{
FMON Data Output
Creates directories and saves data once experiment ends

Written By: Nate Gonzales-Hess (nhess@uoregon.edu)
Last Updated: 7/6/2023
%}

%% Create Mouse ID Folder
folderName = 'D:/FMON_data/' + string(mouse_id);
if ~exist(folderName, 'dir')
    mkdir(folderName);
end

%% Create Protocol Folder
folderName = 'D:/FMON_data/' + string(mouse_id) + '/' + protocol;
if ~exist(folderName, 'dir')
    mkdir(folderName);
end

%% Create Session Folder

% Starting folder number
folderNum = 1;

% Loop until we find a folder number that doesn't exist
while exist(fullfile(folderName, num2str(folderNum)), 'dir') == 7
    folderNum = folderNum + 1;
end

% Create the new folder
mkdir(folderName, num2str(folderNum));

%% Write summary to notes.txt

% Open or create a new text file. 'w' indicates write mode.
notes_directory = folderName + '/' + num2str(folderNum) + '/';

fileID = fopen(notes_directory + 'notes.txt', 'w');

% Check if file opened successfully
if fileID == -1
    error('Failed to open file.');
end

% Note Content
exp = 'Experimenter: ' + string(experimenter);
trn = 'Trainer: ' + string(trainer);
sex = 'Mouse sex: ' + string(mouse_sex);
date = 'Date: ' + string(datetime('now'));
mouse = 'Mouse ID: ' + string(mouse_id);
weight = 'Initial Weight: ' + string(initial_weight);
bias = 'Side Bias: ' + string(side_bias);
session = ['Session: ', num2str(folderNum)];
h2o_calib = 'WATER CALIBRATION';
l_port = ['Left Port: ', num2str(LeftValveTime)];
r_port = ['Right Port: ', num2str(RightValveTime)];
i_port = ['Initiation Port: ', num2str(InitValveTime)];

% Write the text to the file
fprintf(fileID, '%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s',...
    exp, trn, sex, date, mouse, weight, bias, session, h2o_calib,...
    l_port, r_port, i_port);

% Close the file
fclose(fileID);

%% Build Trial Summarry

trialcount = (1:10)';
trialtypes = BpodSystem.Data.TrialTypes';

summary_mat = horzcat(trialcount, trialtypes);
