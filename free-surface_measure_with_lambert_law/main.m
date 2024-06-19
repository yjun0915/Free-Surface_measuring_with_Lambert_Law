%% Requirements
clear;
prompt = {'Enter excel file name saved result:', ...
    'Enter voltage: ', ...
    'Enter concentration (in ppm): ', ...
    'Enter frame per second: ', ...
    'Enter video name: ', ...
    'Enter signal color to use: ', ...
    'Enter frame for line profile: ', ...
    'Enter length per pixel (in mm): '};
dlgtitle = 'Finding absorbance constant';
fieldsize = [1 45; 1 45; 1 45; 1 45; 1 45; 1 45; 1 45; 1 45];
definput = {'result_excel.xlsx', '5V', '10ppm', '120fps', 'example.mp4', 'red', '1', '0.00235'};
answer = inputdlg(prompt,dlgtitle,fieldsize,definput);

excelFileName = answer{1};
vlotage = answer{2};
concentration = answer{3};
fps = str2double(erase(answer{4}, 'fps'));
videoName = answer{5};
selectSignal = answer{6};
measureFrame = str2double(answer{7});
mmPerPixle = str2double(answer{8});

signalColor = ["red" "green" "blue"];
signalNum = size(signalColor, 2);
signalIndex = matches(signalColor, selectSignal);
signalIndex = signalIndex*[1 2 3]';

%% Getting results
sheetName = strcat(vlotage, concentration, answer{4});

initialIntensities = readtable(excelFileName, 'Sheet', strcat('I_0', '_', sheetName), 'VariableNamingRule','preserve');
initialIntensity = initialIntensities{signalIndex, 2};

absorbanceConstants = readtable(excelFileName, 'Sheet', strcat('absorbance', '_', sheetName), 'VariableNamingRule','preserve');
absorbance = absorbanceConstants{signalIndex, 2};

%% Getting video and calculating depth
h = waitbar(0,'1','Name','Reading intensities...',...
    'CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
setappdata(h,'canceling',0);
    
progress = 0;

video = VideoReader(strcat("Videos/", videoName));

sx = video.Width;
sy = video.Height;
measureFrameNum = video.NumFrames;

varTypes = ["double", "double"];
varNames = ["position", "depth"];
varNum = size(varNames, 2);

sz = [sx, varNum];
output_line_x = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

sz = [sy, varNum];
output_line_y = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

varTypes = ["double", "double"];
varNames = ["time", "depth"];
varNum = size(varNames, 2);
sz = [measureFrameNum, varNum];

output_time = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

f = 1;
while video.hasFrame
    if getappdata(h,'canceling')
        break
    end
    waitbar(progress/measureFrameNum, h, ...
        sprintf("%12.2f%% progressing ..", progress/measureFrameNum));

    frame = video.readFrame;
    value = double(frame(:, :, signalIndex));
    
    if f == measureFrame
        output_line_x(:, "position") = table(linspace(0, mmPerPixle*sx, sx)');
        for x = 1:sx
            output_line_x(x, "depth") = {inversing_beer_lambert(value(int32(sy/2), x)+0.01, initialIntensity, absorbance)};
        end

        output_line_y(:, "position") = table(linspace(0, mmPerPixle*sy, sy)');
        for y = 1:sy
            output_line_y(y, "depth") = {inversing_beer_lambert(value(y, int32(sx/2))+0.01, initialIntensity, absorbance)};
        end
    end

    output_time(f, "time") = {f/fps};
    output_time(f, "depth") = {inversing_beer_lambert(value(int32(sy/2), int32(sx/2))+0.01, initialIntensity, absorbance)};

    f = f + 1;
    progress = progress + 1;
end
close(h);

%% Visulize
figure(1);
plot(output_time.depth)