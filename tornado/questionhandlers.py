#!/usr/bin/python

# database imports
from pymongo import MongoClient

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
		feature = data["feature"];

		dbid = self.db.labeledinstances.insert(
			{"feature":feature,"label":label,"dsid":dsid}
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

class AddLabeledInstanceHandler(BaseHandler):
	@tornado.web.asynchronous
	def post(self):
		'''addLocation
		'''

		#print self.request.body;
		data = json.loads(self.request.body);

		dsid = data["dsid"];
		label = data["label"];
		feature = data["feature"];

		dbid = self.db.labeledinstances.insert(
			{"feature":feature,"label":label,"dsid":dsid}
		);

		#self.write_json({"id":str(dbid),"feature":feature,"label":label});
		self.write(data);

class LearnHandler(BaseHandler):
	def post(self):
		'''learn
		'''
		print self.request.body;
		dsid = self.get_int_arg("dsid",default=0);
		
		f=[];
		for a in self.db.labeledinstances.find({"$and": [{"dsid": {"$exists": True}}, {"dsid": dsid}]}):
			feature = a["feature"];
			gps = feature["gps"];
			compass = feature["compass"];

			f.append([float(gps["lat"]),float(gps["long"]),float(compass["x"]),float(compass["y"]),float(compass["z"])]);

		l=[];
		for a in self.db.labeledinstances.find({"$and": [{"dsid": {"$exists": True}}, {"dsid": dsid}]}):
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
		gps = vals["gps"];
		compass = vals["compass"];
		fvals = [float(gps["lat"]),float(gps["long"]),float(compass["x"]),float(compass["y"]),float(compass["z"])];
		dsid  = data['dsid'];

		# load the model from the database (using pickle)
		# we are blocking tornado!! no!!
		if(self.clf.get(dsid) is None):
			print 'Loading Model From DB';
			tmp = self.db.models.find_one({"dsid":dsid});
			self.clf[dsid] = pickle.loads(tmp['model']);
	
		predLabel = self.clf[dsid].predict(fvals);
		self.write_json({"label":str(predLabel)});


class RequestCurrentDatasetId(BaseHandler):
	def get(self):
		'''Get a new dataset ID for building a new dataset
		'''
		if(self.db.labeledinstances.count() == 0):
			sessionId = 0.0;
			self.write_json({"dsid":sessionId});
		else:
			#a = self.db.labeledinstances.find_one({"dsid":{"$exists": True}}).sort("dsid", -1);
			a = self.db.labeledinstances.find_one(sort=[("dsid", -1)]);
			sessionId = float(a['dsid'])+1;
			self.write_json({"dsid":sessionId});
		#self.client.close()
		