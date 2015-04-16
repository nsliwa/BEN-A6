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
		array = [];
		array = self.db.locations.find();

		for loc in array:
			self.write_json({"x":loc["x"],"y":loc["y"],"z":loc["z"]});
			self.write("\n");

class AddLocationHandler(BaseHandler):
	def post(self):
		'''addLocation
		'''
		data = json.loads(self.request.body);

		dsid = data["dsid"];
		label = data["label"];
		feature = data["feature"];

		dbid = self.db.labeledinstances.insert(
			{"feature":feature,"label":label,"dsid":dsid}
		);
		self.write_json({"id":str(dbid),"feature":feature,"label":label});

class LearnHandler(BaseHandler):
	def get(self):
		'''learn
		'''
		dsid = self.get_int_arg("dsid",default=0);
		
		f=[];
		for a in self.db.labeledinstances.find({"dsid":dsid}):
			feature = a["feature"];
			gps = feature["gps"];
			compass = feature["compass"];
			time = feature["time"];

			f.append([gps["lat"],gps["long"],compass["x"],compass["y"],compass["z"],time]);

		l=[];
		for a in self.db.labeledinstances.find({"dsid":dsid}):
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

		data = json.loads(self.request.body);
		
		location = data["location"];
		questions = data["question"];

		self.write_json({"location":location,"question":question});