#!/usr/bin/python

# database imports
from pymongo import MongoClient

import tornado.web

from tornado.web import HTTPError
from tornado.httpserver import HTTPServer
from tornado.ioloop import IOLoop
from tornado.options import define, options

from basehandler import BaseHandler

from sklearn.neighbors import KNeighborsClassifier
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

class AddLabeledDataHandler(BaseHandler):
	def post(self):
		'''getLocations
		'''
		data = json.loads(self.request.body);
		
		# self.db.locations.insert(
		# 	{"location":data["location"]}
		# );
		# array=[];
		# for a in self.db.locations.find({"location": { "$exists": True } }):
		# 	array.append(a["location"]);

		#for loc in array:
		self.write_json(data);
		#	self.write("\n");

class AddLabeledInstanceHandler(BaseHandler):
	@tornado.web.asynchronous
	def post(self):
		'''addLocation
		'''

		#print self.request.body;
		data = self.request.body;

		#dsid = data["dsid"];
		#label = data["label"];
		#feature = data["feature"];

		#dbid = self.db.labeledinstances.insert(
		#	{"feature":feature,"label":label,"dsid":dsid}
		#);
		#self.write_json({"id":str(dbid),"feature":feature,"label":label});
		self.write(data);

class LearnHandler(BaseHandler):
	def post(self):
		'''learn
		'''
		print self.request.body;
		dsid = self.get_int_arg("dsid",default=0);
		
		f=[];
		for a in self.db.labeledinstances.find({"dsid": { "$exists": True } }):
			feature = a["feature"];
			gps = feature["gps"];
			compass = feature["compass"];
			time = feature["time"];

			f.append([gps["lat"],gps["long"],compass["x"],compass["y"],compass["z"],time]);

		l=[];
		for a in self.db.labeledinstances.find({"dsid": { "$exists": True } }):
			l.append(a["label"]);

		c1 = KNeighborsClassifier(n_neighbors=2);
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

		print self.request.body;
		data = json.loads(self.request.body);
		
		location = data["location"];
		questions = data["question"];

		self.write_json({"location":location,"question":question});