# database imports
from pymongo import MongoClient

import os, shutil

# init database connection
client  = MongoClient() # local host, default port
db = client.exploreSMU # database with labeledinstances, models

db.drop_collection('locations')

root = "./Landmarks/"

if os.path.exists(root):
    shutil.rmtree(root)
os.makedirs(root)



locations = [
	["Lyle", ["Hart Center", "Bio Informatics Lab"]],
	["Meadows", []], 
	["Cox", []],
	["Dedman", []],
	["Sports", []],
	["Meadows Museum", []],
	["Fondren Library", []],
	["Residential Commons", []],
	["Testing", ["Starbucks", "Blue Cups", "Candle", "Remote", "Ball"]]
]

for loc in locations:
	print "loc:", loc[0], "landmarks:", loc[1]

	db.locations.insert(
		{
			"location": loc[0],
			"landmarks": loc[1]
		}
	)

	for landmark in loc[1]:
		os.makedirs(root+loc[0]+"/"+landmark)
