import matplotlib.pyplt as plt

# database imports
from pymongo import MongoClient

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
db = client.sklearndatabase # database with labeledinstances, models

# init PCA
n_components = 300
pca = RandomizedPCA(n_components=n_components)







dsid = 0

# initialize feature / label array
features = []
labels = []


# pull out all relevant instances from db 
for a in self.db.labeledinstances.find({"$and": [{"dsid": {"$exists": True}}, {"dsid": dsid}]}):
	# if count % 2 == 0: 
	

	# pull out img in base64
	feature_data = a["feature"];

	# decode current img from base64
	# convert to np array
	img = Image.open(BytesIO(base64.b64decode(feature_data)))
	# downsample
	width = 100
	height = 100
	img = img.resize((width, height), Image.ANTIALIAS)

	# convert to numpy array
	img = np.array(img)

	# convert to grayscale
	gray = color.rgb2gray(img)

	# process hog
	fd, hog_img = hog(gray, orientations=8, pixels_per_cell=(32,32), cells_per_block=(1,1), visualise=False)

	# convert to numpy array and reshape
	gray = np.array(hog_img)
	gray = gray.astype(np.float)

	fvals = gray.reshape( (1, -1) )[0]

	features.append( fvals )

	# process label data
	# pull out label
	label = a["label"]
	labels.append(landmarks.index(label));

features = np.array(features).astype(np.float)
print "f_shape: ", np.shape(f), type(f), type(f[0])
print "l_shape: ", np.shape(l), type(l), type(l[0])

acc = -1
if l: 

	# fit pca to data
	# transform data 
	pca.fit(features)
	features_transformed = pca.transform(features)
	print "f_shape_trans: ", np.shape(features_transformed)
	
	cv = StratifiedKFold(labels, K=3)
	param_dict = {'C':[.1, .001, .00001], "kernel": ['linear', 'rbf']}

	# init classifiers
	c_svc = GridSearchCV(SVC(), cv=cv, n_jobs=-1, param_grid=param_dict)
	c_svc_pca = GridSearchCV(SVC(), cv=cv, n_jobs=-1, param_grid=param_dict)

	c_gnb = GridSearchCV(GaussianNB(), cv=cv, n_jobs=-1, param_grid=param_dict)
	c_gnb_pca = GridSearchCV(GaussianNB(), cv=cv, n_jobs=-1, param_grid=param_dict)

	c_mnnb = GridSearchCV(MultinomialNB(), cv=cv, n_jobs=-1, param_grid=param_dict)
	c_mnnb_pca = GridSearchCV(MultinomialNB(), cv=cv, n_jobs=-1, param_grid=param_dict)

	# fit classifiers
	c_svc.fit(features, labels)
	c_svc_pca(features_transformed, labels)

	c_gnb.fit(features, labels)
	c_gnb_pca(features_transformed, labels)

	c_mnnb.fit(features, labels)
	c_mnnb_pca(features_transformed, labels)

	classifier = c_svc.best_estimator_
	if(classifier.best_score_ < c_svc_pca.best_estimator_.best_score_)
		print "c_svc_pca is better"
		classifier = c_svc_pca.best_estimator_

	if(classifier.best_score_ < c_gnb.best_estimator_.best_score_)
		print "c_gnb is better"
		classifier = c_gnb.best_estimator_

	if(classifier.best_score_ < c_gnb_pca.best_estimator_.best_score_)
		print "c_gnb_pca is better"
		classifier = c_gnb_pca.best_estimator_

	if(classifier.best_score_ < c_mnnb.best_estimator_.best_score_)
		print "c_mnnb is better"
		classifier = c_mnnb.best_estimator_

	if(classifier.best_score_ < c_mnnb_pca.best_estimator_.best_score_)
		print "c_mnnb_pca is better"
		classifier = c_mnnb_pca.best_estimator_

	print "classifier scores: ", classifier.grid_scores_

