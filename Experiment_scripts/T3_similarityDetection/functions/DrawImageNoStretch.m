function tex = DrawImageNoStretch(win, img)
% DrawImageNoStretch  Draw an image without distortion, keep aspect ratio, and auto-center
%
% Usage:
%    DrawImageNoStretch(win, img)
%
% Parameters:
%    win : Psychtoolbox window handle
%    img : Image matrix already loaded by imread

% Create texture
tex = Screen('MakeTexture', win, img);

% Get screen size
[screenXpixels, screenYpixels] = Screen('WindowSize', win);

% Get image dimensions
[imgHeight, imgWidth, ~] = size(img);

% Compute scale factors to maintain aspect ratio
scaleX = screenXpixels / imgWidth;
scaleY = screenYpixels / imgHeight;
scaleFactor = min(scaleX, scaleY);  % Choose the smaller scale

% Scaled image dimensions
newWidth  = imgWidth * scaleFactor;
newHeight = imgHeight * scaleFactor;

% Compute centered position
xCenter = screenXpixels / 2;
yCenter = screenYpixels / 2;
destinationRect = CenterRectOnPointd([0 0 newWidth newHeight], xCenter, yCenter);

% Draw image
Screen('DrawTexture', win, tex, [], destinationRect);

end
