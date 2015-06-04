function [code, dict, dim] = jpegEncode (image)

    dim = size(image);
    fid = fopen('Qtable2.txt','r');
    %array is quantization matrix
    array = fscanf(fid,'%e',[8,inf]);

    JQ = forwardDCT(image,array);

    JQ_vect = reshape(JQ,1,[]);

    uniq_JQ = unique(JQ_vect);
    % Value - # occurrences
    p = histc(JQ_vect,uniq_JQ) / prod(dim);

    [dict, ~] = huffmandict(uniq_JQ,p); % Create dictionary.
    code = huffmanenco(JQ_vect,dict); % Encode the data.

end