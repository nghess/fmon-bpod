%% Make this a function and specify mouse id and session as arguments

%% Pull Out ITI's and Performance for a mouse


% need to remove omissions
time = zeros(session_data.nTrials, 1);
correct = zeros(session_data.nTrials, 1);
trial_types = session_data.TrialTypes;

for ii = 1:session_data.nTrials
    time(ii) = round(session_data.RawEvents.Trial{1, ii}.States.ITI(2) - session_data.RawEvents.Trial{1, ii}.States.ITI(1));
    
    if ~isnan(session_data.RawEvents.Trial{1, ii}.States.CorrectLeft) | ~isnan(session_data.RawEvents.Trial{1, ii}.States.CorrectRight)
        correct(ii) = 1;
    else
        correct(ii) = 0;
    end
end

%% Separate Out Trial Types

l_trials_idx = find(trial_types == 1);
r_trials_idx = find(trial_types == 2);
l_omit_idx = find(trial_types == 3);
r_omit_idx = find(trial_types == 4);

%% Filter Correct list by trial type
L_correct = correct(l_trials_idx);
R_correct = correct(r_trials_idx);
L_o_correct = correct(l_omit_idx);
R_o_correct = correct(r_omit_idx);

% Filter ITI time list by trial type
L_time = time(l_trials_idx);
R_time = time(r_trials_idx);

%% Logistic Regression

% Create synthetic data
rng('default'); % For reproducibility
n = 100; % Number of samples
%time = linspace(0, 10, n)';
%correct = randi([0, 1], n, 1);

% Fit logistic regression model for L trials
[L, dev, stats] = glmfit(L_time, L_correct, 'binomial', 'link', 'logit');
% Fit logistic regression model for R trials
[R, dev, stats] = glmfit(R_time, R_correct, 'binomial', 'link', 'logit');
% Fit logistic regression model for L Omit trials
%[L_o, dev, stats] = glmfit(time, L_o_correct, 'binomial', 'link', 'logit');
% Fit logistic regression model for R Omit trials
%[R_o, dev, stats] = glmfit(time, R_o_correct, 'binomial', 'link', 'logit');

% Generate new time points for prediction
time_new = linspace(0, max(time), 300)';

% Get predicted probabilities
yhat_L = glmval(L, time_new, 'logit');
yhat_R = glmval(R, time_new, 'logit');

% Plotting
figure;

% Scatter plot of original data
scatter(L_time, L_correct, 10, 'MarkerEdgeColor', [0 0 1], 'Marker', 'o');
hold on;
scatter(R_time, R_correct, 20, 'MarkerEdgeColor', [1 0 0], 'Marker', 'x');

hold on;

% Plot the fitted logistic curves
plot(time_new, yhat_L, 'b', 'LineWidth', 2);
plot(time_new, yhat_R, 'r', 'LineWidth', 2);

title('Mouse 2191, Session 17 (DOI)')
xlabel('ITI Duration');
ylabel('Probability of Correct Decision');
legend('Left Trials', 'Right Trials');
grid on;

hold off;
