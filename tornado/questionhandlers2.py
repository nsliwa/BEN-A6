#!/usr/bin/python

# database imports
from pymongo import MongoClient
import gridfs
from PIL import Image

import base64
import numpy as np
import matplotlib.pyplot as plt
from io import BytesIO

import tornado.web

from tornado.web import HTTPError
from tornado.httpserver import HTTPServer
from tornado.ioloop import IOLoop
from tornado.options import define, options

from basehandler import BaseHandler

from sklearn import svm
import pickle
from bson.binary import Binary
import time
import json

class GetLocationHandler(BaseHandler):
	def get(self):
		'''getLocations
		'''
		array=[];
		for a in self.db.locations.find({"location": { "$exists": True } }):
			array.append(a["location"]);

		#for loc in array:
		self.write_json({"locations":array});
		#	self.write("\n");

class AddLocationHandler(BaseHandler):
	def post(self):
		'''getLocations
		'''
		data = json.loads(self.request.body);
		self.db.locations.insert(
			{"location":data["location"]}
		);
		array=[];
		for a in self.db.locations.find({"location": { "$exists": True } }):
			array.append(a["location"]);

		#for loc in array:
		self.write_json({"locations":array});
		#	self.write("\n");

class AddLabeledInstanceHandler(BaseHandler):
	# @tornado.web.asynchronous
	def post(self):
		'''getLocations
		'''
		data = json.loads(self.request.body);

		dsid = data["dsid"];
		label = data["label"];
		feature_data = data["feature"];

		feature_data = feature_data["img"];
		# feature = str(feature_data).decode('base64');

		# img = Image.open(BytesIO(base64.b64decode(feature_data)))
		# img_array = np.array(img)


		# # http://alexk2009.hubpages.com/hub/Storing-large-objects-in-MongoDB-using-Python
		# # create a new gridfs object.
		# fs = gridfs.GridFS(self.db)

		# # store the data in the database. Returns the id of the file in gridFS
		# storedFeature = fs.put(feature_data, encoding='base64')

		# # retrieve what was  stored. 
		# feature =fs.get(storedFeature).read()
		# # plt.imshow(img)
		# # plt.show()
	 
		# # Image.open(feature).convert('RGBA')
		# arr = np.array(feature)

		# # record the original shape
		# shape = arr.shape
		# print type(img_array)

	 # 	with open('/Users/nicolesliwa/Documents/SMU/10-Spring_2015/7323-Mobile_Aps/text_img.png', 'wb') as f:
		# 	f.write(outputdata)

		# print str(feature)[0:50]

		print dsid

		# dbid = self.db.images.insert(
		# 	{"image":storedFeature,"label":label,"dsid":dsid}
		# );

		dbid = self.db.labeledinstances.insert(
			{"feature":feature_data,"label":label,"dsid":dsid}
		);

		# self.db.locations.insert(
		# 	{"location":data["location"]}
		# );
		# array=[];
		# for a in self.db.locations.find({"location": { "$exists": True } }):
		# 	array.append(a["location"]);

		#for loc in array:
		self.write_json({"label":data["label"]});
		#	self.write("\n");

# class AddLabeledInstanceHandler(BaseHandler):
# 	# @tornado.web.asynchronous
# 	def post(self):
# 		'''addLocation
# 		'''

# 		#print self.request.body;
# 		data = json.loads(self.request.body);

# 		dsid = data["dsid"];
# 		label = data["label"];
# 		feature = data["feature"];

# 		print str(feature)

# 		# dbid = self.db.labeledinstances.insert(
# 		# 	{"feature":feature,"label":label,"dsid":dsid}
# 		# );

# 		#self.write_json({"id":str(dbid),"feature":feature,"label":label});
# 		# self.write(data);


# 		self.write_json({"label": label})

class LearnHandler(BaseHandler):
	def get(self):
		'''learn
		'''
		dsid = self.get_int_arg("dsid",default=0);
		print dsid

		# print self.request.body;
		# data = json.loads(self.request.body);

		# dsid = data["dsid"];
		
		f=[];
		for a in self.db.labeledinstances.find({"$and": [{"dsid": {"$exists": True}}, {"dsid": dsid}]}):
			# f.append([float(val) for val in a['feature']])

			storedFeature = a["feature"];

			img = Image.open(BytesIO(base64.b64decode(storedFeature)))
			feature = np.array(img)

			print "feature: ", feature

			print "shape: ", np.shape(feature)

			f.append(feature.reshape((1,-1))[0])

			# plt.imshow(img)
			# plt.show()

			# # n_samples = len(digits.images)
			# data = digits.images.reshape((n_samples, -1))
		 
			# # http://alexk2009.hubpages.com/hub/Storing-large-objects-in-MongoDB-using-Python
			# # create a new gridfs object.
			# fs = gridfs.GridFS(self.db)

			# # retrieve what was  stored. 
			# feature =fs.get(storedFeature).read() 

			# img = Image.open(BytesIO(base64.b64decode(feature)))
			# img_array = np.array(img)

			# f.append(img_array);

			# img = feature["img"];
			# f.append(float(img));

			# gps = feature["gps"];
			# compass = feature["compass"];

			# f.append([float(gps["lat"]),float(gps["long"]),float(compass["x"]),float(compass["y"]),float(compass["z"])]);

		print "shape2: ", np.shape(f)
		print f

		# n_samples = len(f)
		# f = f.reshape((n_samples, -1))


		l=[];
		for a in self.db.labeledinstances.find({"$and": [{"dsid": {"$exists": True}}, {"dsid": dsid}]}):
			print a["label"]
			l.append(a["label"]);

		c1 = svm.SVC();
		acc = -1;
		if l:
			c1.fit(f,l); # training
			lstar = c1.predict(f);

			#c[dsid] = c1
			
			if(self.clf == []):
				self.clf = {dsid: c1};
			else:
				self.clf[dsid] = c1;
				
			acc = sum(lstar==l)/float(len(l));
			bytes = pickle.dumps(c1);
			self.db.models.update({"dsid":dsid},
				{  "$set": {"model":Binary(bytes)}  },
				upsert=True)
		
		self.write_json({"resubAccuracy":acc});


class PredictionHandler(BaseHandler):
	def post(self):
		'''predict
		'''
		
		data = json.loads(self.request.body);

		vals = data["feature"];
		img = vals["img"]
		fvals = img
		# gps = vals["gps"];
		# compass = vals["compass"];
		
		# fvals = [float(gps["lat"]),float(gps["long"]),float(compass["x"]),float(compass["y"]),float(compass["z"])];
		dsid  = data['dsid'];
		print dsid

		# load the model from the database (using pickle)
		# we are blocking tornado!! no!!
		if(self.clf.get(dsid) is None):
			print 'Loading Model From DB';
			tmp = self.db.models.find_one({"dsid":dsid});
			self.clf[dsid] = pickle.loads(tmp['model']);
	
		predLabel = self.clf[dsid].predict(fvals);
		self.write_json({"label":str(predLabel[0])});


class RequestCurrentDatasetId(BaseHandler):
	def get(self):
		'''Get a new dataset ID for building a new dataset
		'''
		if(self.db.labeledinstances.count() == 0):
			sessionId = 0.0;
			self.write_json({"dsid":sessionId});
		else:
			#a = self.db.labeledinstances.find_one({"dsid":{"$exists": True}}).sort("dsid", -1);
			a = self.db.labeledinstances.find_one({"dsid": {"$exists": True}}, sort=[("dsid", -1)]);

			if(a is None):
				sessionId = 0.0;
				self.write_json({"dsid":sessionId});
			else:
				print a["dsid"];
				sessionId = float(a['dsid']);
				self.write_json({"dsid":sessionId});
		#self.client.close()
		