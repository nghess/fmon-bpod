session_duration = 3;  % time in seconds

% If timer from cancelled session is running, stop and delete it.
if exist('t', 'var') == 1 && isa(t, 'timer')
    if strcmp(t.Running, 'on')
        stop(t);
        disp('Previously started timer stopped')
    end
    delete(t);
end

t = timer;
t.StartDelay = session_duration;  % time in seconds
t.TimerFcn = @(obj, event)timeUp(obj, event, session_duration);  % timeUp is defined at end of this file
start(t);

function timeUp(obj, event, duration)
    disp(num2str(duration) + " seconds have elapsed! The session has ended.");
end