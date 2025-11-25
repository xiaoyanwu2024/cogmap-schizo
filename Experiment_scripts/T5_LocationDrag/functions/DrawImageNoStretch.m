function tex = DrawImageNoStretch(win, img)
% DrawImageNoStretch  Draw an image without distortion, keep aspect ratio, and center it automatically
%
% Usage:
%    DrawImageNoStretch(win, img)
%
% Parameters:
%    win : Psychtoolbox window handle
%    img : Image matrix already read with imread

% Create texture
tex = Screen('MakeTexture', win, img);

% Get screen size
[screenXpixels, screenYpixels] = Screen('WindowSize', win);

% Get image size
[imgHeight, imgWidth, ~] = size(img);

% Compute scaling factors to fit the screen while keeping aspect ratio
scaleX = screenXpixels / imgWidth;
scaleY = screenYpixels / imgHeight;
scaleFactor = min(scaleX, scaleY);  % Choose the smaller scaling factor

% Image size after scaling
newWidth  = imgWidth * scaleFactor;
newHeight = imgHeight * scaleFactor;

% Compute centered position
xCenter = screenXpixels / 2;
yCenter = screenYpixels / 2;
destinationRect = CenterRectOnPointd([0 0 newWidth newHeight], xCenter, yCenter);

% Draw the image
Screen('DrawTexture', win, tex, [], destinationRect);

end
