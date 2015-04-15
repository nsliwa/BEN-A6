#!/usr/bin/python

# database imports
from pymongo import MongoClient

import tornado.web

from tornado.web import HTTPError
from tornado.httpserver import HTTPServer
from tornado.ioloop import IOLoop
from tornado.options import define, options

from basehandler import BaseHandler

import time
import json
#import simplejson as json

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

		x = float(data["x"]);
		y = float(data["y"]);
		z = float(data["z"]);

		dbid = self.db.locations.insert(
			{"x":x,"y":y,"z":z}
		);

		self.write_json({"x":x,"y":y,"z":z});

class LearnHandler(BaseHandler):
	def post(self):
		'''learn
		'''
		image = self.get_argument("image");
		flash = self.get_argument("flash");
		location = self.get_argument("location");
		gps = self.get_argument("gps");

		self.write_json({"image":image,"flash":flash,"location":location,"gps":gps});

class PredictionHandler(BaseHandler):
	def get(self):
		'''predict
		'''

		data = json.loads(self.request.body);

		self.write_json({"location":location,"question":question});