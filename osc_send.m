% Create a UDP object
u = udp('127.0.0.1', 8000);

% Open the UDP object
fopen(u);

% Create an OSC message
msg = oscmsgout('/test', 'is', [123, 'hello']);

% Write the OSC message to the UDP object
fwrite(u, msg);

% Close the UDP object
fclose(u);