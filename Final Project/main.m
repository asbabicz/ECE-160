clear
clc

% -------------------------------------------------------------------------
%                                   README
%
% To run this code, you need to make sure there is a folder called
%   "High5_PNG" within the same directory as your main.m function. Within
%   this folder, you should have the 30 frames we want to process. The
%   frames must be named "FRAME000.png", "FRAME001.png", ... "FRAME030.png"
%
% For the purposes of speed, I've re-sized each of the PNG files during the
%   import process. Otherwise this code would take significant time to run
%   (on a fast desktop, ~5 min).
% -------------------------------------------------------------------------

% -------------------------------------------------------------------------
% Import the I frames
%
% Frame order:
%   IBPB | IBPB | IBPB | IBPB | IBPB | IBPB | IBPB | IB
%   ^1     ^5     ^9     ^13    ^17    ^21    ^25    ^29
% -------------------------------------------------------------------------

string             = 'High5_PNG/FRAME0';
originalFrames{30} = []; % Container for the original frames
finalFrames{30}    = []; % Container for the final frames

for x = 1 : 30

    if x < 10
        newString = strcat( string, '0', num2str(x) ); % Add leading zero
	else
        newString = strcat( string, num2str(x) );
    end

    % Import each frames
	originalFrames{x} = double( imresize( rgb2gray( imread( ...
                               strcat(newString, '.png') ) ), [256 384]) );

end

% -------------------------------------------------------------------------
% Encode the I frames and store them into the container of final frames
% -------------------------------------------------------------------------
for x = 1 : 4 : 30

    % Encode
    [code, dict, dim] = Iencode( originalFrames{x} );
    
    % Decode and store
    finalFrames{x}    = Idecode(code, dict, dim);

end

% Manually encode the last I frame and store it
[code, dict, dim] = Iencode( originalFrames{30} );
finalFrames{30}   = Idecode(code, dict, dim);
    
MBsize  = 16; % Macroblock size
p       = 2;  % Search parameter (the larger, the longer the runtime)

% -------------------------------------------------------------------------
% JPEG compress the P frames. This is done using these steps:
%   1. Find motion vectors between I -> P
%   2. Find the motion compensated P frame using the motion vectors
%   3. Calculate the error between the motion compensated P frame and the
%       original (imported) P frame
%   4. (To be implemented...) JPEG encode the error image (for now, we're
%       just using imwrite(...) to export as a JPEG, which works)
% -------------------------------------------------------------------------
for y = 3 : 4 : 30

    I = originalFrames{y - 2};
    P = originalFrames{y};

    % Motion vector between I -> P
    motionVectIP  = motionEstES(I, P, MBsize, p);
    
    % Compensated image between I -> P
    P_comp = motionComp(I, motionVectIP, MBsize);
    
    % Error between reconstructed image and original P frame
    P_error = P - P_comp;

    finalFrames{y} = I - P_error;
    
end

% -------------------------------------------------------------------------
% Calculate the first B frames. This is done using these steps:
%   1. Find motion vectors of B frame from both directions. i.e. from
%       I -> B and from P -> B
%   2. Find two motion compensated B frames using the two motion vectors
%       above
%   3. Average the two motion compensated B frames that we found above
%   4. Calculate the error between the motion compensated B frame we found
%       above and the original (imported) B frame
%   5. (To be implemented...) JPEG encode the error image (for now, we're
%       just using imwrite(...) to export as a JPEG, which works)
% -------------------------------------------------------------------------
for z = 2 : 4 : 28

    I   = originalFrames{z - 1}; % This I is behind the B frame
    B   = originalFrames{z};
    P   = originalFrames{z + 1}; % This P is in front of the B frame

    % Motion vectors between I -> B && P -> B
    motionVectIB = motionEstES(I, B, MBsize, p);
    motionVectPB = motionEstES(P, B, MBsize, p);

    % Compensated images between I -> B && P -> B
    imgCompIB = motionComp(I, motionVectIB, MBsize);
    imgCompPB = motionComp(P, motionVectPB, MBsize);

    % Average the two compensated images to get
    imgCompBavg = (imgCompIB + imgCompPB) / 2;

    % Error between reconstructed image and original B frame 
    Bframe_error = B - imgCompBavg;

    finalFrames{z} = Bframe_error;

end

% -------------------------------------------------------------------------
% Calculate the second B frames. This is done using these steps:
%   1. Find motion vectors of B frame from both directions. i.e. from
%       I -> B and from P -> B
%   2. Find two motion compensated B frames using the two motion vectors
%       above
%   3. Average the two motion compensated B frames that we found above
%   4. Calculate the error between the motion compensated B frame we found
%       above and the original (imported) B frame
%   5. (To be implemented...) JPEG encode the error image (for now, we're
%       just using imwrite(...) to export as a JPEG, which works)
% -------------------------------------------------------------------------
for z = 4 : 4 : 28

    I   = originalFrames{z + 1}; % This I is in front of the B frame
    B   = originalFrames{z};
    P   = originalFrames{z - 1}; % This P is behind the B frame

    % Motion vectors between I -> B && P -> B
    motionVectIB = motionEstES(I, B, MBsize, p) ;
    motionVectPB = motionEstES(P, B, MBsize, p);

    % Compensated images between I -> B && P -> B
    imgCompIB = motionComp(I, motionVectIB, MBsize);
    imgCompPB = motionComp(P, motionVectPB, MBsize);

    % Average the two compensated images to get
    imgCompBavg = (imgCompIB + imgCompPB) / 2;

    % Error between reconstructed image and original B frame 
    Bframe_error = B - imgCompBavg;

    finalFrames{z} = Bframe_error;

end

% -------------------------------------------------------------------------
% Add captions to the appropriate frames
% -------------------------------------------------------------------------

% Import captions from .csv file
captions = readtable('High5_PNG/caption.csv');
size = size( originalFrames{1} );
imgHeight = size(1,1);
imgWidth  = size(1,2);

for x = 1 : height(captions)
    
    Text = char( captions{x,3} );
    H = vision.TextInserter(Text);
    H.Color = [255 255 255];
    H.FontSize = 20; % CHANGE TO 60 FOR FINAL CODE
    H.Location = [ (imgWidth / 5) (5 * imgHeight / 6)]; % CHANGE TO [__ __]
    
	for y = captions{x,1} : ( captions{x,1} + captions{x,2} )
      
        finalFrames{y} = step(H, finalFrames{y});
       
	end
    
end

% -------------------------------------------------------------------------
% Write each new frame to a JPG file. To view the new frames, navigate to
%   the folder where your main.m function is located, and there will be a
%   folder called "High5_JPG". This is where the new frames are located.
% -------------------------------------------------------------------------
for a = 1 : 30

    imwrite( uint8( finalFrames{a} ), strcat( 'High5_JPG/frame', ...
                                                    num2str(a), '.jpg' ) );

end