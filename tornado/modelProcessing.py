# import matplotlib.pyplt as plt

# database imports
from pymongo import MongoClient

# model saving
import gridfs
import pickle
from bson.binary import Binary

# image decoding
import base64
import numpy as np
import matplotlib.pyplot as plt
from io import BytesIO
from PIL import Image
import cv2

# sklearn imports
from sklearn.cross_validation import StratifiedKFold
from sklearn.grid_search import GridSearchCV

from sklearn.naive_bayes import MultinomialNB
from sklearn.naive_bayes import GaussianNB
from sklearn.svm import SVC

from sklearn.decomposition import RandomizedPCA

# skimage imports
from skimage.feature import hog
from skimage import data, color, exposure

# init database connection
client  = MongoClient() # local host, default port
db = client.exploreSMU # database with labeledinstances, models

# init PCA
n_components = 50
pca = RandomizedPCA(n_components=n_components)


for loc in db.locations.find():
	# get current dataset id (i.e. location)
	location = loc["location"]
	landmarks = loc["landmarks"]

	# initialize feature / label array
	features = []
	labels = []

	print "loc:\t", location, "\nlndmrk:\t", landmarks

	for a in db.labeledinstances.find( {"$and": [{"dsid": {"$exists": True}}, {"dsid": location}]} ):
		# process feature data
		# pull out img in base64
		feature_data = a["feature"]

		# decode current img from base64
		# convert to np array
		img = Image.open(BytesIO(base64.b64decode(feature_data)))
		# downsample
		width = 100
		height = 100
		img = img.resize((width, height), Image.ANTIALIAS)
		img = np.array(img)

		# convert img to grayscale
		gray= cv2.cvtColor(img,cv2.COLOR_BGR2GRAY)
		gray = gray.astype(np.float)

		# # convert to grayscale
		# gray = color.rgb2gray(img)

		# process hog
		fd, hog_img = hog(gray, orientations=8, pixels_per_cell=(32,32), cells_per_block=(1,1), visualise=True)

		# convert to numpy array and reshape
		gray = np.array(hog_img)
		gray = gray.astype(np.float)

		fvals = gray.reshape( (1, -1) )[0]

		features.append( fvals )




		# process label data
		# pull out label
		label = a["label"]
		labels.append(landmarks.index(label));

		# print "label:", label, "index:", landmarks.index(label), "shape:", np.shape(gray), np.shape(fvals)

	features = np.array(features).astype(np.float)
	# print "f_shape: ", np.shape(features), type(features)#, type(features[0])
	# print "l_shape: ", labels, np.shape(labels), type(labels)#, type(labels[0])

	acc = -1
	if labels: 

		# # fit pca to data
		# # transform data 
		# pca.fit(features)
		# features_transformed = pca.transform(features)
		# print "f_shape_trans: ", np.shape(features_transformed)
		
		cv = StratifiedKFold(labels, n_folds=3)
		param_dict = {'C':[.1, .01, .001, .0001, .00001], "kernel": ['linear', 'rbf', 'poly', 'sigmoid']}

		# c1 = GaussianNB()#kernel='linear');
		# estimator = GridSearchCV(c1, cv=cv, n_jobs=-1, param_grid={})
		# estimator.fit(features, labels)

		# classifier = estimator.best_estimator_

		# init classifiers
		c_svc = GridSearchCV(SVC(), cv=cv, param_grid=param_dict)
		# c_svc_pca = GridSearchCV(SVC(), cv=cv, param_grid=param_dict)

		c_gnb = GridSearchCV(GaussianNB(), cv=cv, param_grid={})
		# c_gnb_pca = GridSearchCV(GaussianNB(), cv=cv, param_grid={})

		c_mnnb = GridSearchCV(MultinomialNB(), cv=cv, param_grid={})
		# c_mnnb_pca = GridSearchCV(MultinomialNB(), cv=cv, param_grid={})

		# fit classifiers
		c_svc.fit(features, labels)
		# c_svc_pca.fit(features_transformed, labels)

		c_gnb.fit(features, labels)
		# c_gnb_pca.fit(features_transformed, labels)

		c_mnnb.fit(features, labels)
		# c_mnnb_pca.fit(features_transformed, labels)

		classifier = c_svc
		print "\nclassifier scores-svc:\n\t", c_svc.grid_scores_, c_svc.best_score_
		print "\nclassifier scores-gnb:\n\t", c_gnb.grid_scores_, c_gnb.best_score_
		print "\nclassifier scores-mnnb:\n\t", c_mnnb.grid_scores_, c_mnnb.best_score_
		# if(classifier.best_score_ < c_svc_pca.best_estimator_.best_score_):
		# 	print "c_svc_pca is better"
		# 	classifier = c_svc_pca.best_estimator_

		if(classifier.best_score_ < c_gnb.best_score_):
			print "c_gnb is better"
			classifier = c_gnb

		# if(classifier.best_score_ < c_gnb_pca.best_estimator_.best_score_):
		# 	print "c_gnb_pca is better"
			# classifier = c_gnb_pca.best_estimator_

		if(classifier.best_score_ < c_mnnb.best_score_):
			print "c_mnnb is better"
			classifier = c_mnnb

		classifier = classifier.best_estimator_

		print "\nbest classifier:\n\t", classifier

		# if(classifier.best_score_ < c_mnnb_pca.best_estimator_.best_score_):
		# 	print "c_mnnb_pca is better"
		# 	classifier = c_mnnb_pca.best_estimator_

		# print "classifier scores: ", estimator.grid_scores_, estimator.best_score_
	
		# pickle model for binary file save
		bytes = pickle.dumps(classifier);
		# bytes_pca = pickle.dumps(pca)

		if classifier:
			print "\nc_coef:\n\t", classifier.coef_
			print "\nc_shape:\n\t", np.shape(classifier.coef_), np.shape(classifier.n_support_) 

		# http://alexk2009.hubpages.com/hub/Storing-large-objects-in-MongoDB-using-Python
		# create a new gridfs object.
		fs = gridfs.GridFS(db)

		# store the model in the database. Returns the id of the file in gridFS
		model_id = fs.put(Binary(bytes))
		# pca_id = fs.put(Binary(bytes_pca))

		# store model_id in db
		db.models.update(
			{ "dsid":location },
			{ "$set": 
				{"model":model_id}  
			},
			upsert=True)

	else:
		print "\tno labeled instances found for classification"