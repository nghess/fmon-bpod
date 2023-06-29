%t = tcpclient('127.0.0.1', 11235, "Timeout", 20, "ConnectTimeout", 30);

% Create a TCP/IP server object
t = tcpip('127.0.0.1', 11235, 'NetworkRole', 'client');

% Set the input buffer size
t.InputBufferSize = 30000;

% Open the connection
fopen(t);

% Create a variable called data
%data = 1:10;

% Write the data to the object t
%write(t, data)