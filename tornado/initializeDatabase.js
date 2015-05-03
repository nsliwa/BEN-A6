// clear database
use exploreSMU
db.locations.drop()

db.createColection("locations")
db.locations.insert(
	{
		location: "Lyle",
		landmarks: ["Hart Center", "Bio Informatics Lab"]
	}
)

db.locations.insert(
	{
		location: "Meadows",
		landmarks: []
	}
)

db.locations.insert(
	{
		location: "Cox",
		landmarks: []
	}
)

db.locations.insert(
	{
		location: "Dedman",
		landmarks: []
	}
)

db.locations.insert(
	{
		location: "Sports",
		landmarks: []
	}
)

db.locations.insert(
	{
		location: "Meadows Museum",
		landmarks: []
	}
)

db.locations.insert(
	{
		location: "Fondren Library",
		landmarks: []
	}
)