import os
import csv
import shutil

src_img = 'dummy.png'
splits = {
    'train': 'data/splits/train_split.csv',
    'val': 'data/splits/val_split.csv',
    'test': 'data/splits/test_split.csv'
}

for split, csv_path in splits.items():
    dest_dir = f'data/raw/{split}_images'
    os.makedirs(dest_dir, exist_ok=True)
    with open(csv_path, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            id_code = row['id_code']
            if not id_code.endswith('.png'):
                id_code += '.png'
            dest_path = os.path.join(dest_dir, id_code)
            shutil.copy(src_img, dest_path)
print("Dummy data generated successfully!")
