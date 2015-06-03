% ------------------------------------------------------------------------------
% Iencode
% ------------------------------------------------------------------------------
%
% Inputs
%   img - a DOUBLE image (grayscale image)
%   
% Outputs  
%   code - bitstream to decode into a resulting JPEG compressed image
%   dict - dictionary used to decode the bitstream
%   dim  - dimentions of the original image (needed to decoce the bitstream!)
%   
%   This function encode a DOUBLE image (grayscale image) into a bistream to
%       later be decoded by a decoder (Idecode)
%   
% ------------------------------------------------------------------------------

function [code, dict, dim] = Iencode( img )

	dim       = size( img);
    fid       = fopen('Qtable2.txt', 'r');
    array     = fscanf(fid, '%e', [8, inf]);
    JQ        = forwardDCT(img, array);
    JQ_vect   = reshape(JQ, 1, []);
    uniq_JQ   = unique(JQ_vect);
    p         = histc(JQ_vect, uniq_JQ) / prod(dim);
    [dict, ~] = huffmandict(uniq_JQ, p);
    sig       = JQ_vect;
    code      = huffmanenco(sig, dict);

end