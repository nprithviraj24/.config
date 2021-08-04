exp=exp2
cust=38
cfg=small_obj
thresh=0.6
# file_types=(jpeg, JPG, png)

mkdir -p my_s3/eval
aws s3 cp s3://skyqraft-data-science/dev_test_outputs/yolo-faces-and-license-plates/"$exp"/ my_s3/eval --recursive

mkdir -p my_s3/cust"$cust"
aws s3 cp s3://skyqraft-map-ui/prod/"$cust"/ my_s3/cust"$cust" --recursive

echo "classes=2" > my_s3/eval/obj_cust"$cust".data
echo "names=my_s3/eval/obj.names" >> my_s3/eval/obj_cust"$cust".data

# for typ in ${file_types[@]}; do
# 	find my_s3/cust"$cust" | grep "$typ" >> cust"$cust".txt
# done

find my_s3/cust"$cust" -name "*.jpeg" >> cust"$cust".txt
find my_s3/cust"$cust" -name "*.JPG" >> cust"$cust".txt
find my_s3/cust"$cust" -name "*.png" >> cust"$cust".txt


mv cust"$cust".txt my_s3/eval/cust"$cust".txt

./darknet detector test my_s3/eval/obj_cust"$cust".data my_s3/eval/"$cfg".cfg my_s3/eval/backup/"$cfg"_best.weights -dont_show -thresh "$thresh" -save_labels < my_s3/eval/cust"$cust".txt

python3 reshape-imgs.py my_s3/cust"$cust"

# train script in aws-gpu-2
# nohup ./darknet detector train data/obj.data my_s3/small_obj.cfg my_s3/yolov4-obj_best.weights -dont_show -clear -map &

# $ cat data/obj.data
# classes = 2
# train = data/train.txt
# valid = data/valid.txt
# names = data/obj.names
# backup = data/backup/
