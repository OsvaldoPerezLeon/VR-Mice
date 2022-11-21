function Grating(angle, angle2, f, f2, s, d, c, o)
%___________________________________________________________________
% Parameters:
% angle, angle2 = Angle of the gratings with respect to the vertical direction.
% f, f2 = Frequency of gratings in cycles per pixel.
% s, d, c, o = 1x2 matrix of randomization, 0 is non-random, 1 is random 
%        index position refers to left or right side of the screen
%
% The function ends after a key press, or after movieDurationSecs have elapsed.
%
% This function works best on one monitor, or on multiple monitors that use
% the same graphics card and digital port and an extended display. 
% 
% If all monitors are attached to the same graphics card and if one of the
% monitors on the card is set to primary display, this toolbox will support
% multiple monitors. 
% 
% 
% Notes on using multiple monitors:
%
% The toolbox may report all monitors, but not display your stimulus.
% The primary display may be the only monitor that your stimulus is
% displayed on.
% 
% Right click on your desktop and go to the NVIDIA control panel, you may
% be able to extend your desktop so that your windows computer registers
% multiple monitors as one. 
%
%
% This function uses Screen('DrawTexture') in combination with GLSL texture
% draw shaders to efficiently combine two drifting gratings superimposed to each other.
%
%
% HISTORY
% 3/31/09 mk Written.
% 8/19/16 Kristina Hill krishill@mit.edu, Modified.
% _________________________________________________________________________

% User Parameters
movieDurationSecs = 90;
speedcoefficient = [25 25]; % larger coefficient = slower speed, CANNOT BE 0
texsize = 900;              % Half-Size of the grating image
visiblesize=2*texsize+1;    % grating parameter
waitframes = 1;             % wait between frames
rand_frequency = 120;       % number of frames between instances of randomization
color1 = [255 0 0];
color2 = [0 255 0];

% Initialize dummy counters
mxold = 0;
myold = 0;
x_pos_1 = 0;      % absolute x position
y_pos_1 = 0;      % absolute y position
x_pos_2 = 0;
y_pos_2 = 0;
f_counter = 1;  % frequency of randomization
count = 1;

yoffsets = [];
mouse_position = zeros(100,4);
speeds = [];

if nargin < 8 || isempty(f)
    f=0.01;      % Grating cycles/pixel
    p=ceil(1/f); % pixels/cycle, rounded up.
    fr=f*2*pi;   % frequency
end;

if nargin < 7 || isempty(f2)  
    f2=0.02;       % Grating cycles/pixel
    p2=ceil(1/f2); % pixels/cycle, rounded up.
    fr2=f2*2*pi;   % frequency
end;

if nargin < 6 || isempty(angle)
    % Angle of the grating, default
    angle=45;
end;

if nargin < 5 || isempty(angle2)
    % Angle of the grating, default
    angle2=30;
end;

if  nargin < 4 || isempty(s)
    % default to non-random speed
    s = [0 0]; 
end

if  nargin < 3 || isempty(d)
    % default to non-random direction
    d = [0 0];  
end

if  nargin < 2 || isempty(c)
    % default to non-random color
    c = [0 0];  
end

if  nargin < 1 || isempty(o)
    % default to non-random orientation
    o = [0 0];  
end

s_ind = find(s);
d_ind = find(d);
c_ind = find(c);
o_ind = find(o);

try 
    AssertOpenGL;
    
    % Get dimensions for the screen
    screenNumber = max(Screen('Screens'));
    pos = get(0, 'MonitorPositions');  % dimensions of screen setup
    [x_max, y_max] = Screen('WindowSize', screenNumber); % max dimensions of one screen
    
    % Find the color values which correspond to white and black.
    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);

    % Round gray to integral number, to avoid roundoff artifacts with some
    % graphics cards:
    gray = white / 2;
    contrastcoefficient = [white-gray, (white-gray)/2];  % larger coefficient = more contrast, SHOULD NOT BE 0
    
    % Create one single static grating image:
    x = meshgrid(-texsize:texsize + p, -texsize:texsize);
    grating = gray + contrastcoefficient(1)*cos(fr*x);
    
    % Build a second drifting grating texture
    x2 = meshgrid(-texsize:texsize + p2, -texsize:texsize);
    grating2 = gray + contrastcoefficient(2)*cos(fr2*x2); 
    
    % source rectangle
    srcRect = [0 0 visiblesize visiblesize];
    
    if angle; rotateMode1 = kPsychUseTextureMatrixForRotation; else rotateMode1 = []; end
    if angle2; rotateMode2 = kPsychUseTextureMatrixForRotation; else rotateMode2 = []; end
    
    %% Create On-Screen Window
    if screenNumber <= 1
        x_min = pos(1, 1);
        y_min = pos(1, 2);
        SetMouse(0, 0, screenNumber);
        
        % Open a double buffered fullscreen window with a gray background:
        [w, rect] = Screen('OpenWindow', screenNumber, gray);
        [x_center, y_center] = RectCenter(rect); % center coordinates of one screen
        
        % Create a special texture drawing shader for masked texture drawing:
        glsl = MakeTextureDrawShader(w, 'SeparateAlphaChannel');
        
        AssertGLSL;
    
        % Enable alpha blending for typical drawing of masked textures:
        Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        
        % Store alpha-masked grating in texture and attach the special 'glsl'
        % texture shader to it:
        gratingtex1 = Screen('MakeTexture', w, grating, [], [], [], [], glsl);
        gratingtex2 = Screen('MakeTexture', w, grating2, [], [], [], [], glsl);    
    end
    
    if screenNumber > 1
        x_min = pos(screenNumber, 1);
        y_min = pos(screenNumber, 2);
        SetMouse(0, 0, screenNumber);
        rect = Screen('Rect', 0);
        [w, rect] = Screen('OpenWindow', 0, rect);
        [x_center, y_center] = RectCenter(rect); % center coordinates of one screen
        
        % Create a special texture drawing shader for masked texture drawing:
        glsl = MakeTextureDrawShader(w, 'SeparateAlphaChannel');
        
        AssertGLSL;
    
        % Enable alpha blending for typical drawing of masked textures:
        Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        
        % Store alpha-masked grating in texture and attach the special 'glsl'
        % texture shader to it:
        gratingtex1 = Screen('MakeTexture', w, grating, [], [], [], [], glsl);
        gratingtex2 = Screen('MakeTexture', w, grating2, [], [], [], [], glsl);   
    end
    
    %%
    % Recompute p, this time without the ceil() operation from above.
    % Otherwise we will get wrong drift speed due to rounding!
    % Probably not be necessary 
    p = 1/f; % pixels/cycle
    p2 = 1/f2;
    
    % Query duration of monitor refresh interval:
    ifi = Screen('GetFlipInterval', w);

    % Perform initial Flip to sync us to the VBL and for getting an initial
    % VBL-Timestamp for our "WaitBlanking" emulation:
    vbl = Screen('Flip', w);
    
    % We run at most 'movieDurationSecs' seconds if user doesn't abort via keypress.
    vblendtime = vbl + movieDurationSecs;


    while (vbl < vblendtime) && ~KbCheck
        %% Track Mouse Position
        HideCursor;
        KbReleaseWait;
        [mx, my, ~]=GetMouse(w);      

        mouse_position(f_counter,1)=x_pos_1;
        mouse_position(f_counter,2)=y_pos_1;
        mouse_position(f_counter,3)=x_pos_2;
        mouse_position(f_counter,4)=y_pos_2;
        
        if (mx~=mxold || my~=myold) 
            dx_1 = mx - mxold;
            dy_1 = my - myold;
            dx_2 = mx - mxold;
            dy_2 = my - myold;
            
            % once mouse reaches limit in the x-direction
            if(mx>=x_max-5 || mx<=x_min+5) 
                % reset to opposite side of the screen
                if mx>=x_max-5
                    SetMouse(x_min,my);
                    [mx, my, ~]=GetMouse(w);
                    dx_1 = 1;
                    dx_2 = 1;
                elseif mx<=x_min+5
                    SetMouse(x_max-7,my);
                    [mx, my, ~]=GetMouse(w);
                    dx_1= -1;
                    dx_2= -1;
                end
        
            % once mouse reaches limit in the y-direction    
            elseif(my>=y_max-5 || my<=y_min+5)
                % reset to opposite side of the screen
                if my<=y_min+5
                    SetMouse(mx,y_max-7);
                    [mx, my, ~]=GetMouse(w);
                    dy_1 = -1;
                    dy_2 = -1;
                elseif my >= y_max-5
                    SetMouse(mx,y_min);
                    [mx, my, ~]=GetMouse(w);
                    dy_1 = 1;
                    dy_2 = 1;
                end
            end
        end
        
        % update reference position
        mxold = mx;
        myold = my;
        
        % Randomization Loop
        % Randomly change direction of grating every rand_frequency # of frames
        if isempty(d_ind) == 0 && mod(count,2) == 0
            dx_1 = -dx_1;
            if d_ind(1) == 1 
                dx_1 = -dx_1;
                dy_1 = -dy_1;
            elseif d_ind(2) == 1 
                dx_2 = -dx_2;
                dy_2 = -dy_2;
            end   
        end    
        
        if mod(f_counter, rand_frequency) == 0
            count = count + 1;
        end
        
        % track absolute mouse position as if one huge screen
        x_pos_1 = x_pos_1+dx_1;
        y_pos_1 = y_pos_1+dy_1;
        x_pos_2 = x_pos_2+dx_2;
        y_pos_2 = y_pos_2+dy_2;
        
        offset_pos_1 = (x_pos_1+y_pos_1)/2;
        % offset_pos_2 = (x_pos_2+y_pos_2)/2;
        offset_pos_2 = (x_pos_1+y_pos_1)/2;

        % set the position of the mouse to the yoffset of the grating
        yoffset = mod(offset_pos_1/speedcoefficient(1),p);
        yoffset2 = mod(offset_pos_2/speedcoefficient(2),p2);
        
        yoffsets(f_counter, 1) = yoffset;
        yoffsets(f_counter, 2) = yoffset2;
        
        
        %% Randomization 
        % Randomly changing speed of the grating, every rand_frequency # frames
        if isempty(s_ind) == 0 && mod(f_counter, rand_frequency) == 0   
            % reset the speed to initial values
            speedcoefficient = [25 25];
            % multiply speed by a random coefficient
            if size(s_ind) == 2
                speedcoefficient(1) = 25.* randi([2,10]);
                speedcoefficient(2) = 25.* randi([2,10]);
            else   
                speedcoefficient(s_ind) = speedcoefficient(s_ind).*randi([2, 10])/5;
            end
        end
        
        speeds = [speeds; speedcoefficient];
        
        % Randomly change color of grating every rand_frequency # of frames
        if isempty(c_ind) == 0 && mod(f_counter, rand_frequency) == f_counter - 1
            colors = [color1; color2];  % hex colors RGB
            colors(c_ind, 1) = randi(300); 
            colors(c_ind, 2) = randi(300);
            colors(c_ind, 3) = randi(300);    
            color1 = colors(1,:);
            color2 = colors(2,:);
        end
        
        % Randomly change angle of grating every rand_frequency # of frames
        if isempty(o_ind) == 0 && mod(f_counter, rand_frequency) == 0
            if o_ind(1) == 1
                angle = randi(180); 
            elseif o_ind(2) == 1
                angle2 = randi(180);
            end         
        end
        
        %%  Area of projection
        if screenNumber>1
            size_vector_1 = pos(1,:);
            size_vector_2 = pos(2,:);
            if screenNumber == 3
                size_vector_3 = pos(3,:);
            end
        else
            size_vector_1 = [0 -y_center x_center y_max+y_center]; % displays on left screen
            size_vector_2 = [x_center -y_center x_max+x_center y_max+y_center]; % display on right screen
        end
        
        %% Draw the Grating
        % We pass the pixel offset 'yoffset' as a parameter to
        % Screen('DrawTexture'). The attached 'glsl' texture draw shader
        % will apply this 'yoffset' pixel shift to the RGB or Luminance
        % color channels of the texture during drawing, thereby shifting
        % the gratings. 
        
        if screenNumber <= 1
            % Draw first grating texture, rotated by "angle":
            Screen('DrawTexture', w, gratingtex1, srcRect, size_vector_1, angle, [], [], color1, [], rotateMode1, [0, yoffset, 0, 0]);
            Screen('DrawTexture', w, gratingtex2, srcRect, size_vector_2, angle, [], [], color2, [], rotateMode2, [0, yoffset2, 0, 0]);
        
            
        elseif screenNumber > 1    
            % Draw first grating texture, rotated by "angle":
            Screen('DrawTexture', w, gratingtex1, srcRect, size_vector_1, angle, [], [], color1, [], rotateMode1, [0, yoffset, 0, 0]);
            % Draw 2nd grating texture, rotated by "angle2":
            Screen('DrawTexture', w, gratingtex2, srcRect, size_vector_2, angle2, [], [], color2, [], rotateMode2, [0, yoffset2, 0, 0]);
          
        end      
        % Update counters
        f_counter = f_counter + 1;
        
        
        % Flip 'waitframes' monitor refresh intervals after last redraw.
        vbl = Screen('Flip', w, vbl + (waitframes - 0.5) * ifi);
    end
    
    Screen('CloseAll')
    
catch
    % This "catch" section executes in case of an error in the "try" section
    % above. Importantly, it closes the onscreen window if it is open.
    Screen('CloseAll');
    psychrethrow(psychlasterror);

end %try..catch.   

assignin('base', 'mouse_position', mouse_position);
assignin('base', 'yoffsets', yoffsets);
assignin('base', 'speeds', speeds);

figure
plot(mouse_position(:,1), mouse_position(:,2));
title('Mouse Movement')
figure
plot(yoffsets(:,1));
title('Grating Offset')
   