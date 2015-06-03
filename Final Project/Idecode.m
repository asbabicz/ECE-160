% ------------------------------------------------------------------------------
% Idecode
% ------------------------------------------------------------------------------
%
% Inputs
%   code - bitstream to decode into a resulting JPEG compressed image
%   dict - dictionary used to decode the bitstream
%   dim  - dimentions of the original image (needed to decoce the bitstream!)
%   
% Outputs  
%   JPEGimg - the resulting JPEG compressed image. A DOUBLE image (grayscale
%             image
%
%   This function decodes a bitsream produced by the function Iencode. It
%   produces a JPEG compressed DOUBLE image (grayscale image). To view this
%   image, type "imshow( uint8(JPEGimg) )"
%   
% ------------------------------------------------------------------------------

function [JPEGimg] = Idecode( code, dict, dim )

    reverseJQ = huffmandeco(code, dict);
    JQOG      = reshape(reverseJQ, dim(1,1), dim(1,2));
    fid       = fopen('Qtable2.txt', 'r');
    array     = fscanf(fid, '%e', [8,inf]);
    JPEGimg   = inverseDCT(JQOG, array);

end