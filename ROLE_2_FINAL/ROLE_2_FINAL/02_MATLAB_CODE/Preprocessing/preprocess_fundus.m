function output = preprocess_fundus(I)

claheImage = preprocess_clahe(I);

output = preprocess_denoise(claheImage);

end