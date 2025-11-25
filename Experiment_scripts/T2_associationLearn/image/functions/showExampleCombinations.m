function tex = showExampleCombinations(win, instrImg, baseTrials)

% Set path
stimDir = fullfile(pwd, 'stimuli');
tex = DrawImageNoStretch(win, instrImg);

% Image parameters
imgW = 100; imgH = 100;  % Size of each image
boxW = 310; boxH = 180;  % Estimated area for each combination block

[screenX, screenY] = Screen('WindowSize', win);

imgW = 100; imgH = 100;
boxW = 310; boxH = 180;
colSpacing = 100;
rowSpacing = 40;
intraSpacing = 30;

% Loop through and draw all 6 combinations
for i = 1:6
    age = baseTrials{i,1};
    time = baseTrials{i,2};
    food = baseTrials{i,3};

    % Determine row & column
    row = ceil(i / 3);
    col = mod(i - 1, 3) + 1;

    % Top-left position of current combination block
    totalWidth = 3 * boxW + 2 * colSpacing;
    totalHeight = 2 * boxH + rowSpacing;
    originX = (screenX - totalWidth) / 2;
    originY = (screenY - totalHeight) / 1.75;

    blockX = originX + (col - 1) * (boxW + colSpacing);
    blockY = originY + (row - 1) * (boxH + rowSpacing);

    % Box rect
    boxRect = [blockX, blockY, blockX + boxW + intraSpacing, blockY + boxH];

    % Image paths
    ageImg = imread(fullfile(stimDir, ['age/',age '.tiff']));
    timeImg = imread(fullfile(stimDir, ['time/', time '.tiff']));
    foodImg = imread(fullfile(stimDir, ['food/', food '.tiff']));

    % Convert to textures
    ageTex = Screen('MakeTexture', win, ageImg);
    timeTex = Screen('MakeTexture', win, timeImg);
    foodTex = Screen('MakeTexture', win, foodImg);

    % Image drawing positions (3 images side by side)
    ageDst = CenterRectOnPoint([0 0 imgW imgH], blockX + imgW/2, blockY + boxH/2);
    timeDst = CenterRectOnPoint([0 0 imgW imgH], blockX + imgW*1.5 + 10, blockY + boxH/2);
    foodDst = CenterRectOnPoint([0 0 imgW imgH], blockX + imgW*2 + intraSpacing + imgW/2, blockY + boxH/2);

    % Draw images
    Screen('DrawTexture', win, ageTex, [], ageDst);
    Screen('DrawTexture', win, timeTex, [], timeDst);
    Screen('DrawTexture', win, foodTex, [], foodDst);

    % Draw border box
    Screen('FrameRect', win, [0 0 0], boxRect, 3);

    % Close textures
    Screen('Close', [ageTex, timeTex, foodTex]);
end

end
