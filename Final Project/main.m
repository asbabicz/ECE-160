clear
clc

%% ------------------------------------------------------------------------
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

%% ------------------------------------------------------------------------
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

%% ------------------------------------------------------------------------
% JPEG compress the I frames (encode then decode) and store them into the
%   container of final frames
% -------------------------------------------------------------------------
for x = 1 : 4 : 30

    % Encode
    [code, dict, dim] = Iencode( originalFrames{x} );
    
    % Decode and store
    finalFrames{x}    = Idecode(code, dict, dim);

end

% JPEG compress (encode then decode) the last I frame and store it into the
%   containter of final frames
[code, dict, dim] = Iencode( originalFrames{30} );
finalFrames{30}   = Idecode(code, dict, dim);

%% ------------------------------------------------------------------------
% JPEG compress the P frames. This is done using these steps:
%
%   1. Find motion vectors between I -> P, then Huffman encode it
%   2. Find the motion compensated P frame using the motion vectors above
%   3. Calculate the error between the motion compensated P frame and the
%       original (imported) P frame, then encode it
%   4. Decode the encoded error between the motion compensated P frame and
%       the original (imported) P frame
%   5. Huffman decode the motion vectors between I -> P
%   6. Reshape the result from step 5 using the original frame dimensions
%   7. Our resulting JPEG compressed P frame is the motion compensation
%       between the JPEG compressed I frame, using the reshaped motion
%       vectors from step 6
% -------------------------------------------------------------------------

MBsize  = 16; % Macroblock size
p       = 2;  % Search parameter (the larger, the longer the runtime)

for y = 3 : 4 : 30

    I = originalFrames{y - 2};
    P = originalFrames{y};

    % ---------------------------------------------------------------------
    % Encoding process
    % ---------------------------------------------------------------------
    
    % (1)
    motionVectIP                     = motionEstES(I, P, MBsize, p);
    [codeMV_IP, dictMV_IP, dimMV_IP] = huffEncode(motionVectIP);
    
    % (2)
    P_comp = motionComp(I, motionVectIP, MBsize);
    
    % (3)
    P_error = P - P_comp;
    [codeP_error, dictP_error, dimP_error] = jpegEncode(P_error);
    
	% ---------------------------------------------------------------------
    % Decoding process
    % ---------------------------------------------------------------------
    
    % (4)
    P_error_d = jpegDecode(codeP_error, dictP_error, dimP_error);
    
    % (5)
    reverseJQ = huffmandeco(codeMV_IP, dictMV_IP);
    
    % (6)
    motionVectDecoded = reshape(reverseJQ, dimMV_IP(1,1), dimMV_IP(1,2));
    
   	% ---------------------------------------------------------------------
    % Storing
    % ---------------------------------------------------------------------
    
    % (7)
    finalFrames{y} = motionComp(finalFrames{y-2}, motionVectDecoded, ...
                                                       MBsize) + P_error_d;
    
end

%% ------------------------------------------------------------------------
% Calculate the first B frames. This is done using these steps:
%   1. Find motion vectors of B frame from both directions. i.e. from
%       I -> B and from P -> B, then Huffman encode them
%   2. Find two motion compensated B frames using the two motion vectors
%       above, then average them
%   3. Calculate the error between the motion compensated B frame we found
%       above and the original (imported) B frame, then encode it
%   4. Huffman decode the encoded motion vectors from step 1, then reshape
%      according to the dimentions of the orignal frame
%   5. Decode the encoded error from step 3
%   6. Find the motion compensation between the decoded I and P frame
%      using the decoded motion vectors from step 4
%   7. Resulting JPEG compressed B frame is the average of the motion
%      compensated images from above, added to the decoded error from
%      step
% -------------------------------------------------------------------------
for z = 2 : 4 : 28

    I   = originalFrames{z - 1}; % This I is behind the B frame
    B   = originalFrames{z};
    P   = originalFrames{z + 1}; % This P is in front of the B frame

    % ---------------------------------------------------------------------
    % Encoding process
    % ---------------------------------------------------------------------
    
    % (1)
    motionVectIB                         = motionEstES(I, B, MBsize, p);
	motionVectPB                         = motionEstES(P, B, MBsize, p);
    [codeMV_IB, dictMV_B_IB, dimMV_B_IB] = huffEncode(motionVectIB);
    [codeMV_PB, dictMV_B_IP, dimMV_B_IP] = huffEncode(motionVectPB);

    % (2)
    imgCompIB   = motionComp(I, motionVectIB, MBsize);
    imgCompPB   = motionComp(P, motionVectPB, MBsize);
    imgCompBavg = (imgCompIB + imgCompPB) / 2;

    % (3)
    B_error = B - imgCompBavg;
    [codeB_error, dictB_error, dimB_error] = jpegEncode(B_error);
    
    % ---------------------------------------------------------------------
    % Decoding process
    % ---------------------------------------------------------------------
    
    % (4)
    reverseJQIB = huffmandeco(codeMV_IB, dictMV_B_IB);
    JQOGIB      = reshape(reverseJQIB, dimMV_B_IB(1,1), dimMV_B_IB(1,2));
    reverseJQPB = huffmandeco(codeMV_PB, dictMV_B_IP);
    JQOGPB      = reshape(reverseJQPB, dimMV_B_IP(1,1), dimMV_B_IP(1,2));
    
    % (5)
    B_error_d = jpegDecode(codeB_error, dictB_error, dimB_error);
    
    % (6)
    temp1 = motionComp(finalFrames{z - 1}, JQOGIB, MBsize);
    temp2 = motionComp(finalFrames{z + 1}, JQOGPB, MBsize);
    
    % ---------------------------------------------------------------------
    % Storing
    % ---------------------------------------------------------------------
    
    % (7)
    finalFrames{z} = B_error_d + (temp1 + temp2)/2;

end

%% ------------------------------------------------------------------------
% Calculate the second B frames. This is done using these steps:
%   1. Find motion vectors of B frame from both directions. i.e. from
%       I -> B and from P -> B, then Huffman encode them
%   2. Find two motion compensated B frames using the two motion vectors
%       above, then average them
%   3. Calculate the error between the motion compensated B frame we found
%       above and the original (imported) B frame, then encode it
%   4. Huffman decode the encoded motion vectors from step 1, then reshape
%      according to the dimentions of the orignal frame
%   5. Decode the encoded error from step 3
%   6. Find the motion compensation between the decoded I and P frame
%      using the decoded motion vectors from step 4
%   7. Resulting JPEG compressed B frame is the average of the motion
%      compensated images from above, added to the decoded error from
%      step
% -------------------------------------------------------------------------
for z = 4 : 4 : 28

    I   = originalFrames{z + 1}; % This I is in front of the B frame
    B   = originalFrames{z};
    P   = originalFrames{z - 1}; % This P is behind the B frame

    % ---------------------------------------------------------------------
    % Encoding process
    % ---------------------------------------------------------------------    
    
    % (1)
    motionVectIB                         = motionEstES(I, B, MBsize, p);
	motionVectPB                         = motionEstES(P, B, MBsize, p);
    [codeMV_IB, dictMV_B_IB, dimMV_B_IB] = huffEncode(motionVectIB);
    [codeMV_PB, dictMV_B_IP, dimMV_B_IP] = huffEncode(motionVectPB);

    % (2)
    imgCompIB   = motionComp(I, motionVectIB, MBsize);
    imgCompPB   = motionComp(P, motionVectPB, MBsize);
    imgCompBavg = (imgCompIB + imgCompPB) / 2;

    % (3)
    B_error = B - imgCompBavg;
    [codeB_error, dictB_error, dimB_error] = jpegEncode(B_error);

    % ---------------------------------------------------------------------
    % Decoding process
    % ---------------------------------------------------------------------
    
    % (4)
    reverseJQIB = huffmandeco(codeMV_IB, dictMV_B_IB);
    JQOGIB      = reshape(reverseJQIB, dimMV_B_IB(1,1), dimMV_B_IB(1,2));
    reverseJQPB = huffmandeco(codeMV_PB, dictMV_B_IP);
    JQOGPB      = reshape(reverseJQPB, dimMV_B_IP(1,1), dimMV_B_IP(1,2));
    
    % (5)
    B_error_d = jpegDecode(codeB_error, dictB_error, dimB_error);
    
    % (6)
    temp1 = motionComp(finalFrames{z + 1}, JQOGIB, MBsize);
    temp2 = motionComp(finalFrames{z - 1}, JQOGPB, MBsize);

    % ---------------------------------------------------------------------
    % Storing
    % ---------------------------------------------------------------------
    
    % (7)
    finalFrames{z} = B_error_d + (temp1 + temp2)/2;

end

%% ------------------------------------------------------------------------
% Add captions to the appropriate frames
% -------------------------------------------------------------------------

captions = readtable('High5_PNG/caption.csv');
size = size( originalFrames{1} );
imgHeight = size(1,1);
imgWidth  = size(1,2);

for x = 1 : height(captions)
    
    Text = char( captions{x, 3} );
    H = vision.TextInserter(Text);
    H.Color    = [255 255 255]; % Black
    H.FontSize = 20;
    H.Location = [ (imgWidth / 5) (5 * imgHeight / 6)];
    
	for y = captions{x,1} : ( captions{x,1} + captions{x,2} )
      
        finalFrames{y} = step(H, finalFrames{y});
       
	end
    
end

%% ------------------------------------------------------------------------
% Write each new frame to a JPG file. To view the new frames, navigate to
%   the folder where your main.m function is located, and there will be a
%   folder called "High5_JPG". This is where the new frames are located.
% -------------------------------------------------------------------------
for a = 1 : 30

    imwrite( uint8( finalFrames{a} ), strcat( 'High5_JPG/frame', ...
                                                    num2str(a), '.jpg' ) );

end