from os import walk
import os, sys
import base64
from pymongo import MongoClient

client  = MongoClient() # local host, default port
db = client.exploreSMU # database with labeledinstances, models

root = "./Landmarks/"

for (dirpath, dirnames, filenames) in walk(root):
	for (directory_path, directory_names, file_names) in walk(dirpath):
	    if dirpath != directory_path:
	    	for f in file_names:
	    		if f != ".DS_Store":

	    			path =  directory_path+"/"+f

	    			dsid = directory_path.split(root)[1].split("/")[0]
	    			label = directory_path.split(root)[1].split("/")[1]

	    			print "path:", directory_path.split(root)[1].split("/")
	    			print path
	    			with open(path, "rb") as img:
					    encoded_img = base64.b64encode(img.read())

					    dbid = db.labeledinstances.insert(
							{"feature":encoded_img,"label":label,"dsid":dsid}
						);

					# os.remove(path)
