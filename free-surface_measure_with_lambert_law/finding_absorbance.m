%% Requirements
clear;
prompt = {'Enter depth settings (in mm):', ...
    'Enter voltage: ', ...
    'Enter concentration (in ppm): ', ...
    'Enter frame per second: ', ...
    'Enter video name width depth: ', ...
    'Enter excel file name to save result: '};
dlgtitle = 'Finding absorbance constant';
fieldsize = [1 45; 1 45; 1 45; 1 45; 1 45; 1 45];
definput = {'4, 5, 6, 7, 8, 9, 10, 11', '5V', '10ppm', '120fps', 'videoname_with_depth_', 'result_excel'};
answer = inputdlg(prompt,dlgtitle,fieldsize,definput);

depthCell = split(answer{1});
vlotage = answer{2};
concentration = answer{3};
fps = str2double(erase(answer{4}, 'fps'));
videoName = answer{5};
filename = answer{6};

depthNum = size(depthCell, 1);
depthMat = double(zeros(1, depthNum));

for depthIndex = 1:depthNum
    eachDepth = str2double(erase(depthCell{depthIndex}, ','));
    depthMat(depthIndex) = eachDepth;
end

statisticalTypeArr = ["max" "mean" "min"];
statisticalTypeNum = size(statisticalTypeArr, 2);

signalColor = ["red" "green" "blue"];
signalNum = size(signalColor, 2);

varTypes = ["double", "string", "double", "string"];
varNames = ["depth(mm)", "signal color", "statistical value", "what is it"];
varNum = size(varNames, 2);
sz = [depthNum*statisticalTypeNum*signalNum, varNum];

output = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

%% Getting video and fill output
h = waitbar(0,'1','Name','Reading intensities...',...
    'CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
setappdata(h,'canceling',0);
    
progress = 0;
for depthIndex = 1:depthNum
    if getappdata(h,'canceling')
        break
    end
    eachDepth = depthMat(depthIndex);
    video = VideoReader(strcat('Videos/', videoName, string(eachDepth), '.mp4'));
    
    videoFrameNum = video.NumFrames;
    means = double(zeros(1, videoFrameNum));

    for signalIndex = 1:signalNum
        frameIndex = 1;
        while video.hasFrame
            if getappdata(h,'canceling')
                break
            end
            waitbar(progress/(depthNum*signalNum*(videoFrameNum+statisticalTypeNum)), h, ...
                sprintf("%d/%d progressing ..", depthIndex, depthNum));

            frame = readFrame(video);
            value = frame(:, :, signalIndex); 
            means(frameIndex) = mean(value, [1 2 3]);
            frameIndex = frameIndex + 1;

            progress = progress + 3;
        end
        statisticalVal = [max(means), mean(means, 'all'), min(means)];

        for statisticalType = 1:statisticalTypeNum
            if getappdata(h,'canceling')
                break
            end
            waitbar(progress/(depthNum*signalNum*(videoFrameNum+statisticalTypeNum)), h, ...
                sprintf("%d/%d progressing ...", depthIndex, depthNum));

            index = (((depthIndex-1))*signalNum...
                +(signalIndex-1))*statisticalTypeNum+...
                statisticalType;

            output(index, :) = ...
                {depthMat(depthIndex), ...
                signalColor(signalIndex), ...
                statisticalVal(statisticalType), ...
                statisticalTypeArr(statisticalType)};

            progress = progress + 1;
        end
    end
end
delete(h);

%% Calculating
varTypes = ["string", "double"];
varNames = ["signal color", "intensity"];
varNum = size(varNames, 2);
sz = [3, varNum];

initialIntensities = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

varTypes = ["string", "double"];
varNames = ["signal color", "absorbance"];
varNum = size(varNames, 2);
sz = [3, varNum];

absorbanceConstants = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
    
for signalIndex = 1:signalNum
    pickColor = signalColor(signalIndex);

    idx = matches(output.("signal color"), pickColor);
    val = output(idx, :);

    boxchart(val.("depth(mm)"), val.("statistical value"));

    f = fit(val.("depth(mm)"), val.("statistical value"), "exp1");
    initialIntensitie = f.a;
    absorbanceConstant = -f.b;

    initialIntensities(signalIndex, :) = {pickColor, initialIntensitie};
    absorbanceConstants(signalIndex, :) = {pickColor, absorbanceConstant};
end

excelfilename = strcat(filename, '.xlsx');
sheetName = strcat(vlotage, concentration, answer{4});
writetable(initialIntensities, excelfilename, 'Sheet', strcat('I_0', '_', sheetName));
writetable(absorbanceConstants, excelfilename, 'Sheet', strcat('absorbance', '_', sheetName));