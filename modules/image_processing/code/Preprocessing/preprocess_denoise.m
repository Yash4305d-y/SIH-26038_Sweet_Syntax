function output = preprocess_denoise(I)

output = imgaussfilt(I, 0.8);

end