%{
FMON Data Output
Creates directories and saves data once experiment ends

Written By: Nate Gonzales-Hess (nhess@uoregon.edu)
Last Updated: 7/6/2023
%}

%% Read in variables from base workspace
BpodSystem = evalin('base', 'BpodSystem');
experimenter = evalin('base', 'experimenter');
trainer = evalin('base', 'trainer');
protocol = evalin('base', 'protocol');
mouse_sex = evalin('base', 'mouse_sex');
mouse_id = evalin('base', 'mouse_id');
initial_weight = evalin('base', 'initial_weight');
thermistor_type = evalin('base','thermistor_type');
odorant = evalin('base', 'odorant');
sniffing = evalin('base', 'sniffing');
side_bias = evalin('base', 'side_bias');
LeftValveVolume = evalin('base', 'LeftValveVolume');
RightValveVolume = evalin('base', 'RightValveVolume');
InitValveVolume = evalin('base', 'InitValveVolume');

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

% Open or create a new text file. 'w' indicates write mode.
data_directory = folderName + '/' + num2str(folderNum) + '/';

%% Save BpodSystem Data
save(data_directory + 'BpodSystem.mat', 'BpodSystem')

%% Build Trial Summarry

trialtypes = BpodSystem.Data.TrialTypes';
n = length(trialtypes);
trialcount = (1:n)';
start_time = zeros(1, n)';
end_time = zeros(1, n)';

% Trial initiation and end timestamp
for i = 1:length(trialtypes)
    trial_start = BpodSystem.Data.RawEvents.Trial{1, i}.States.WaitForInitPoke(2);
    trial_end = BpodSystem.Data.RawEvents.Trial{1, i}.States.ConfirmPortOut(2);
    start_time(i) = trial_start;
    end_time(i) = trial_end;
    
end


summary_mat = horzcat(trialcount, trialtypes, start_time, end_time);

% Save the matrix to a CSV file
writematrix(summary_mat, data_directory + 'trialsummary.csv');

%% Write summary to notes.txt

fileID = fopen(data_directory + 'notes.txt', 'w');

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
odor = 'Odorant: ' + string(odorant);
sniff = 'Sniffing: ' + string(sniffing);
therm = 'Thermistor Type: ' + string(thermistor_type); 
session = ['Session: ', num2str(folderNum)];
h2o_calib = 'WATER CALIBRATION';
l_port = ['Left Port: ', num2str(LeftValveVolume*10)];
r_port = ['Right Port: ', num2str(RightValveVolume*10)];
i_port = ['Initiation Port: ', num2str(InitValveVolume*10)];

% Write the text to the file
fprintf(fileID, '%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n\n%s\n%s\n%s\n%s',...
    exp, trn, sex, date, mouse, weight, bias, session, odor, sniff, therm,...
    h2o_calib, l_port, r_port, i_port);

% Close the file
fclose(fileID);

%% Open Notepad to display the file
notes_filename = data_directory + 'notes.txt';
system("start %windir%\system32\notepad.exe " + notes_filename);

%% Copy DAQ .dat files over
sniff_dat = "NiDAQ_sniff.dat";
poke_dat = "NiDAQ_poke.dat";
video = "rawvideo.avi";

movefile("D:/" + sniff_dat, data_directory + sniff_dat);
movefile("D:/" + poke_dat, data_directory + poke_dat);
movefile("F:/rawvideos/" + video, data_directory + video);
