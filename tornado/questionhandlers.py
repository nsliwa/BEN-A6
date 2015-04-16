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
	def post(self):
		'''learn
		'''
		dsid = self.get_int_arg("dsid",default=0);

		f=[];
		

class PredictionHandler(BaseHandler):
	def post(self):
		'''predict
		'''

		data = json.loads(self.request.body);
		
		location = data["location"];
		questions = data["question"];

		self.write_json({"location":location,"question":question});