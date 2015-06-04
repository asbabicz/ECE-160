% ECE 160 Project Pseudo Code
% Dont try to run ! 
clc;clear all; close all;
%% Load stuff and Initialize variables
addpath(genpath('../mpeg'));
I = double(imresize(rgb2gray(imread('../High5_PNG/FRAME007.png')),[256 384]));
B = double(imresize(rgb2gray(imread('../High5_PNG/FRAME008.png')),[256 384]));
P = double(imresize(rgb2gray(imread('../High5_PNG/FRAME009.png')),[256 384]));

N_macro = 8;
p = 16;
%% I frame encoding
encoded_I = JPEG1(I); % asserted importance for standard codec so that you won't have to pass
% along your dictionaries evrytime you encode a frame
%% Pframe encoding
motionVect = motionEstES(I, P, N_macro, p) ; % Motion Vectors
P_comp_temporary = motionComp(I, motionVect, N_macro);

P_Error = P - P_comp_temporary ; % Residual 
encoded_error_P = JPEG1(P_Error); % Encoded residual bitstream
encoded_motion_vectors_P = motion_vectors_encode(motionVect); % Encoded motion vector 
encoded_P = [encoded_motion_vectors_P, encoded_error_P]; % Collective bitstream for P frame
%% Bframe encoding

motionVectI = motionEstES(I, B, N_macro, p) ; % Motion Vectors Forward Flow
motionVectP = motionEstES(P, B, N_macro, p) ; % Motion Vectors Backward Flow

B_comp_I = motionComp(I, motionVectI, N_macro);
B_comp_P = motionComp(P, motionVectP, N_macro);

B_Recons = (B_comp_I + B_comp_P) / 2;

B_error = B - B_Recons ; % Residual

encoded_error_B = JPEG1(B_Error); % Encoded residual bitstream
encoded_motion_vectors_B_I = motion_vectors_encode(motionVectI); % Encoded motion vector 
encoded_motion_vectors_B_P = motion_vectors_encode(motionVectP); % Encoded motion vector 
encoded_B = [encoded_motion_vectors_B_I, ...
    encoded_motion_vectors_B_P, encoded_error_B]; % Collective bitstream for B frame
%% Iframe decoding
Id = inverse_JPEG(encoded_I); % Decoded I frame
%% Pframe decoding
P_error_d = inverse_JPEG(encoded_error_P);
motionVect_d = motion_vectors_decode(encoded_motion_vectors_P); 
Pd = motionComp(Id, motionVect_d, N_macro)+P_error_d; % Decoded P frame
%% Bframe decoding
B_error_d = inverse_JPEG(encoded_error_B);
motionVectI_d = motion_vectors_decode(encoded_motion_vectors_B_I);
motionVectP_d = motion_vectors_decode(encoded_motion_vectors_B_P);

temp1 = motionComp(Id, motionVectI_d, N_macro);
temp2 = motionComp(Pd, motionVectP_d, N_macro);
Bd = B_error_d + (temp1 + temp2) / 2; % Decoded B frame
%% Reshuffling and saving
% Name Id as 'Decoded Frame 1'
% Name Bd as 'Decoded Frame 2'
% Name Pd as 'Decoded Frame 3'