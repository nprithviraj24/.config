import random, os, sys
import cv2
from glob import glob
classes = ['Human Face',
           'License Plate',
			]
typ = "jpeg";  print(f"{typ} types only. ")

colors = [(204, 204, 0), (51, 51, 255) ] 

abs_path = str(sys.argv[1]) # absolute path of the images
thresh_folder= str(sys.argv[2]) # assumes that txt files are stored in threshold folder

img_paths = glob(abs_path+f"**/*.{typ}", recursive=True)
print()

# cv2.namedWindow("image_name")
for path in img_paths:
	image = cv2.imread(str(path))
	h, w, _ = image.shape
	
	img_name = path.split("/")[-1]
	common_path = path.split("/")[:-1]
	common_path.append(thresh_folder) 
	# import ipdb; ipdb.set_trace()
	txt_path = "/".join(common_path)+str(img_name.replace(f".{typ}", ".txt"))

	with open(txt_path, 'r') as f:
		data = f.read().splitlines()
	if data:
		print(f"{img_name}")
		for line in data:
			class_ind, x, y, width, height = line.split(' ')
			class_ind, x, y, width, height = int(class_ind), float(x), float(y), float(width), float(height)
			# print(class_ind, x, y, w, h)
			x1, y1 = int((x - width / 2) * w), int((y - height / 2) * h)
			x2, y2 = int((x + width / 2) * w) , int((y + height / 2) * h) 
			org = (x1, y1 - 30)
			fontScale = 1
			font = cv2.FONT_HERSHEY_SIMPLEX
			color = colors[class_ind]
			text = classes[class_ind]
			thickness = 1
			cv2.rectangle(image, (x1, y1), (x2, y2), color, 2)
			image = cv2.putText(image, text,
								org, font, fontScale, color, thickness, cv2.LINE_AA)
			
		img_name = path.split("/")[-1]
		cv2.imwrite(f'{ abs_path }/inference/{img_name}', image)
	
	# cv2.imshow("image_name", image )

	# cv2.waitKey()
	# if k==27:    # Esc key to stop
	# 	break

# and finally destroy/Closing all open windows
# cv2.destroyAllWindows() 