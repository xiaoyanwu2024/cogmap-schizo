function [choice, rt] = presentTrial(win, instrDir, t_age, t_time, shuffledFoodNames, xCenter, yCenter)
% Load images
ageImg = imread(fullfile(instrDir, 'age', [t_age '.tiff']));
timeImg = imread(fullfile(instrDir, 'time', [t_time '.tiff']));
texAge = Screen('MakeTexture', win, ageImg);
texTime = Screen('MakeTexture', win, timeImg);

% Display the two images on top (Time and Age)
Screen('FillRect', win, 255);
Screen('DrawTexture', win, texTime, [], CenterRectOnPoint([0 0 150 150], xCenter - 100, yCenter - 200));
Screen('DrawTexture', win, texAge,  [], CenterRectOnPoint([0 0 150 150], xCenter + 100, yCenter - 200));

% Display 6 food images and numeric labels at the bottom
nOptions = 6;
optionSpacing = 120;
optionWidth = 80;
totalWidth = nOptions * optionWidth + (nOptions - 1) * optionSpacing;
startX = xCenter - totalWidth / 2 + optionWidth / 2;

% --- Draw food images and record their positions ---
rectList = cell(1, nOptions);  % Store clickable region for each food image
for k = 1:nOptions
    foodImg = imread(fullfile(instrDir, 'food', [shuffledFoodNames{k} '.tiff']));
    tex = Screen('MakeTexture', win, foodImg);
    xPos = startX + (k-1) * (optionWidth + optionSpacing);
    yPos = yCenter + 50;
    dstRect = CenterRectOnPoint([0 0 optionWidth optionWidth], xPos, yPos);
    rectList{k} = dstRect;  % Save the rect for mouse hit test
    Screen('DrawTexture', win, tex, [], dstRect);
    DrawFormattedText(win, ['(' num2str(k) ')'], xPos - 15, yPos + 60, [0 0 0]);
end

% Flip to the screen and start timing
Screen('Flip', win);
tStart = GetSecs;
ShowCursor;

% Wait for mouse click
clicked = false;
choice = '';
rt = NaN;
while ~clicked
    [x, y, buttons] = GetMouse(win);
    if any(buttons)
        for k = 1:nOptions
            if IsInRect(x, y, rectList{k})
                choice = shuffledFoodNames{k};
                rt = GetSecs - tStart;
                clicked = true;
                break;
            end
        end
    end
end
HideCursor;
end
