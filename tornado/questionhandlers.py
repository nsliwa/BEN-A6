#!/usr/bin/python

# database imports
from pymongo import MongoClient

# image decoding
import base64
import numpy as np
import matplotlib.pyplot as plt
from io import BytesIO
from PIL import Image
import cv2

# model saving
import gridfs

import tornado.web

from tornado.web import HTTPError
from tornado.httpserver import HTTPServer
from tornado.ioloop import IOLoop
from tornado.options import define, options

from basehandler import BaseHandler

from sklearn import svm
from sklearn.decomposition import PCA
from sklearn.decomposition import RandomizedPCA
from sklearn.grid_search import GridSearchCV
import pickle
from bson.binary import Binary
import time
import json

# init PCA
n_components = 200
# pca = PCA(n_components=n_components)
pca = RandomizedPCA(n_components=n_components)

class GetLocationHandler(BaseHandler):
	def get(self):
		'''AddLocation
		'''
		array=[];
		for a in self.db.locations.find({"location": { "$exists": True } }):
			array.append(a["location"]);

		self.write_json({"locations":array});

class AddLocationHandler(BaseHandler):
	def post(self):
		'''GetLocations
		'''
		data = json.loads(self.request.body);
		loc_id = self.db.locations.find_one({"location_id": {"$exists": True}}, sort=[("dsid", -1)]);

		self.db.locations.insert(
			{"location":data["location"], "location_id": loc_id+1}
		);

		array=[];
		for a in self.db.locations.find({"location": { "$exists": True } }):
			array.append(a["location"]);

		self.write_json({"locations":array});

class AddLabeledInstanceHandler(BaseHandler):
	# @tornado.web.asynchronous
	def post(self):
		'''AddLearningData
		'''
		# get json from post
		data = json.loads(self.request.body);

		# parse out 1st lvl json
		dsid = data["dsid"];
		label = data["label"];
		feature_data = data["feature"];

		# parse out 2nd lvl json (img inside data)
		# keep as base64 encode
		# feature now directly contains img data (don't parse out img from dict)
		feature_data = feature_data["img"];

		dbid = self.db.labeledinstances.insert(
			{"feature":feature_data,"label":label,"dsid":dsid}
		);

		print "added instance: dsid -", dsid, "label-", label

		self.write_json({"label":data["label"]});


class InstancePredictionHandler(BaseHandler):
	def post(self):
		'''PredictLocation
		'''
		
		# get json from post
		data = json.loads(self.request.body);

		# parse out 1st lvl json
		dsid  = data['dsid'];
		feature_data = data["feature"];

		print "dsid: ", dsid

		# parse out 2nd lvl json (img inside data)
		feature_data = feature_data["img"]

		# decode img from base64
		# convert to np array
		img = Image.open(BytesIO(base64.b64decode(feature_data)))
		img = np.array(img)

		# convert img to grayscale
		gray= cv2.cvtColor(img,cv2.COLOR_BGR2GRAY)
		gray = gray.astype(np.float)

		# # convert grayscale img to edges
		# edges = cv2.Canny(gray,100,200)

		# # get SIFT features from grayscale
		# sift = cv2.SIFT()
		# kp, des = sift.detectAndCompute(gray,None)

		# reshape img array into 1d array
		# apply pca transform
		# fvals now contains feature data for prediction
		fvals = gray.reshape( (1, -1) )[0]
		fvals = pca.transform(fvals)
		

		# load model from memory if exists, else:
		# load the model from the database (using pickle and GridFS)

		# if memory models !empty but dsid !exist in db
		if(not self.clf == []):
			if(self.clf.get(dsid) is None):
				print 'Loading Model From DB';
				tmp = self.db.models.find_one({"dsid":dsid});
				model_id = tmp['model']

				# http://alexk2009.hubpages.com/hub/Storing-large-objects-in-MongoDB-using-Python
				# create a new gridfs object.
				fs = gridfs.GridFS(self.db)

				# retrieve model that was stored using model_id
				# unpickle binary
				storedModel = fs.get(model_id).read()
				model = pickle.loads(storedModel);

				# store for later
				self.clf[dsid] = model

		# if memory models not initialized
		else:
			print 'Loading Model From DB and Initializing';
			tmp = self.db.models.find_one({"dsid":dsid});
			model_id = tmp['model']

			# http://alexk2009.hubpages.com/hub/Storing-large-objects-in-MongoDB-using-Python
			# create a new gridfs object.
			fs = gridfs.GridFS(self.db)

			# retrieve model that was stored using model_id
			# unpickle binary
			storedModel = fs.get(model_id).read()
			model = pickle.loads(storedModel);

			# initialize memory models
			self.clf = {dsid: model};
		
		model = self.clf[dsid]
		print "dsid: ", dsid, " | model data: ", model

		if model:
			print model.coef_
			print np.shape(model)
		
		# predicted label
		predLabel_id = model.predict(fvals);
		predLabel = self.db.locations.find_one({"location_id":int(predLabel_id[0])});

		print "predicted label: ", predLabel

		self.write_json({"label":str(predLabel[0])});

class LearnModelHandler(BaseHandler):
	def get(self):
		'''learn
		'''
		dsid = self.get_int_arg("dsid",default=0);
		
		# pull out all relevant instances from db 
		f=[];
		for a in self.db.labeledinstances.find({"$and": [{"dsid": {"$exists": True}}, {"dsid": dsid}]}):
			# pull out img in base64
			feature_data = a["feature"];

			# decode current img from base64
			# convert to np array
			img = Image.open(BytesIO(base64.b64decode(feature_data)))
			img = np.array(img)


			gray= cv2.cvtColor(img,cv2.COLOR_BGR2GRAY)
			gray = gray.astype(np.float)

			# # convert grayscale img to edges
			# edges = cv2.Canny(gray,100,200)

			# # get SIFT features from grayscale
			# sift = cv2.SIFT()
			# kp, des = sift.detectAndCompute(gray,None)

			# reshape img array into 1d array
			# apply pca transform
			# fvals now contains feature data for prediction
			fvals = gray.reshape( (1, -1) )[0]

			f.append( fvals )
			
			# cv2.imshow(gray)
			# cv2.imshow('img', gray)


		f = np.array(f).astype(np.float)
		print "f_shape: ", np.shape(f)
		# print f


		# pull out corresponding labels from db
		l=[];
		print "labels: "
		for a in self.db.labeledinstances.find({"$and": [{"dsid": {"$exists": True}}, {"dsid": dsid}]}):
			location = self.db.locations.find_one({"location":a["label"]});

			print "\t", a["label"], location["location_id"]
			l.append(location["location_id"]);

		print "label: ", np.shape(l), type(l), type(l[0])

		acc = -1;
		if l:
			# fit pca to data
			# transform data 
			pca.fit(f)
			f_transformed = pca.transform(f)
			print "f_trans_shape: ", np.shape(f_transformed)
			print "label_shape: ", np.shape(l)

			# training: fit model with transformed data
			# c1.fit(f_transformed, l)
			# lstar = c1.predict(f_transformed)

			c1 = svm.SVC(kernel='linear');
			estimator = GridSearchCV(c1, cv=3, n_jobs=-1, param_grid={'C':[.1, .001, .00001], "kernel": ['linear', 'rbf']})
			estimator.fit(f_transformed, l)
			c1 = estimator.best_estimator_
			lstar = c1.predict(f_transformed)

			print "estimator scores: ", estimator.grid_scores_
			
			# either init in-memory models or append new one
			if(self.clf == []):
				self.clf = {dsid: c1};
			else:
				self.clf[dsid] = c1;

			print "dsid: ", dsid, " | model data: ", self.clf[dsid]

			# accuracy if holding back some data				
			acc = sum(lstar==l)/float(len(l));
			print "accuracy: ", acc

			self.write_json({"resubAccuracy":acc});

			# pickle model for binary file save
			bytes = pickle.dumps(c1);

			if c1:
				print "c1_coef: ", c1.coef_
				print "c1_shape: ", np.shape(c1.coef_), np.shape(c1.n_support_) 

			# http://alexk2009.hubpages.com/hub/Storing-large-objects-in-MongoDB-using-Python
			# create a new gridfs object.
			fs = gridfs.GridFS(self.db)

			# store the model in the database. Returns the id of the file in gridFS
			model_id = fs.put(Binary(bytes))

			# store model_id in db
			self.db.models.update({"dsid":dsid},
				{  "$set": {"model":model_id}  },
				upsert=True)
		
		else: 
			self.write_json({"resubAccuracy-1":acc, "l-length": np.shape(l) });

class RequestNewDatasetId(BaseHandler):
	def get(self):
		'''Get a new dataset ID for building a new dataset
		'''
		a = self.db.labeledinstances.find_one({"dsid": {"$exists": True}}, sort=[("dsid", -1)]);

		sessionID = 0.0

		if(a is None):
			sessionId = 0.0;
		else:
			print a["dsid"];
			sessionId = float(a['dsid'])+1;

		print "new dsid: ", sessionId
		
		self.write_json({"dsid":sessionId});
		#self.client.close()

class RequestCurrentDatasetId(BaseHandler):
	def get(self):
		'''Get a new dataset ID for building a new dataset
		'''
		sessionID = 0.0

		if(self.db.labeledinstances.count() == 0):
			sessionId = 0.0;
		else:
			a = self.db.labeledinstances.find_one({"dsid": {"$exists": True}}, sort=[("dsid", -1)]);

			if(a is None):
				sessionId = 0.0;
			else:
				print a["dsid"];
				sessionId = float(a['dsid']);

		print "new dsid: ", sessionId
		
		self.write_json({"dsid":sessionId});
		#self.client.close()
		