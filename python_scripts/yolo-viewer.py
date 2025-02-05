import cv2
import numpy as np
from random import randint

with open('D:/Qupath/Project3model/yolo/light_zone_dark_zone/val/labels/CaseKI67_0001 [d=4,x=8592,y=53756,w=3120,h=3120].txt', 'r') as f:
    labels = f.read().splitlines()
img = cv2.imread('D:/Qupath/Project3model/yolo/light_zone_dark_zone/val/images/CaseKI67_0001 [d=4,x=8592,y=53756,w=3120,h=3120].jpg')
h,w = img.shape[:2]

for label in labels:
    class_id, *poly = label.split(' ')
    
    poly = np.asarray(poly,dtype=np.float16).reshape(-1,2) # Read poly, reshape
    poly *= [w,h] # Unscale
    
    cv2.polylines(img, [poly.astype('int')], True, (randint(0,255),randint(0,255),randint(0,255)), 2) # Draw Poly Lines
    # cv2.fillPoly(img, [poly.astype('int')], (randint(0,255),randint(0,255),randint(0,255)), cv2.LINE_AA) # Draw area


    cv2.imshow('img with poly', img)
    cv2.waitKey(0)