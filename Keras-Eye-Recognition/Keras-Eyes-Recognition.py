# ---------------------------------------------------------------------------------
"""
@author: Jakub Tlach
"""
# ---------------------------------------------------------------------------------
print("\n---------------> Importing the libraries\n")
# ---------------------------------------------------------------------------------

import cv2
import os

import numpy as np
from keras import backend as K
from sklearn.model_selection import train_test_split
from sklearn.utils import shuffle

K.set_image_dim_ordering('tf')

from keras.utils import np_utils
from keras.models import Sequential
from keras.layers.core import Dense, Dropout, Activation, Flatten
from keras.layers.convolutional import MaxPooling2D, Conv2D

# ---------------------------------------------------------------------------------
print("\n---------------> Setting the variables\n")
# ---------------------------------------------------------------------------------

PATH = os.getcwd()
# Define data path
data_path = PATH + '/data-eyes'
data_dir_list = os.listdir(data_path)

img_rows=100
img_cols=100
num_channel=4
num_epoch=30

# Define the number of classes
num_classes = 3





# ---------------------------------------------------------------------------------
print("\n---------------> Loading the images\n")
# ---------------------------------------------------------------------------------

img_data_list = []

for dataset in data_dir_list:
	img_list = os.listdir(data_path + '/' + dataset)
	print ('Loaded the images of dataset - ' + '{}\n'.format(dataset))
	for img in img_list:
		input_img = cv2.imread(data_path + '/' + dataset + '/' + img)

		# ----------------------------------------------------
		# Comment, when RGB images
		# ----------------------------------------------------
		#input_img = cv2.cvtColor(input_img, cv2.COLOR_BGR2GRAY)
		#input_img = cv2.resize(input_img, (100, 100))

		img_data_list.append(input_img)

img_data = np.array(img_data_list)
img_data = img_data.astype('float32')
img_data /= 255

print (img_data.shape)

# ----------------------------------------------------
# Comment, when RGB images
# ----------------------------------------------------
#img_data = np.expand_dims(img_data, axis=4)

print (img_data.shape)





# ---------------------------------------------------------------------------------
print("\n---------------> Assigning Labels\n")
# ---------------------------------------------------------------------------------

num_of_samples = img_data.shape[0]
labels = np.ones((num_of_samples,), dtype='int64')

# Labels for loaded images
labels[0:300] = 0
labels[300:600] = 1
labels[600:900] = 2

#names = ["hitoe", "futae", "okubutae"]

# Convert class labels to on-hot encoding
Y = np_utils.to_categorical(labels, num_classes)

# Shuffle the dataset
x, y = shuffle(img_data, Y, random_state=2)

# Split the dataset
X_train, X_test, y_train, y_test = train_test_split(x, y, test_size=0.2, random_state=2)





# ---------------------------------------------------------------------------------
print("\n---------------> Defining the model\n")
# ---------------------------------------------------------------------------------

input_shape = img_data[0].shape
print(input_shape)

model = Sequential()

model.add(Conv2D(32, 3, 3, border_mode='same', input_shape=(input_shape)))
model.add(Activation('relu'))
model.add(Conv2D(32, 3, 3))
model.add(Activation('relu'))

model.add(MaxPooling2D(pool_size=(2, 2)))
model.add(Dropout(0.5))

model.add(Conv2D(64, 3, 3))
model.add(Activation('relu'))
model.add(Conv2D(64, 3, 3))
model.add(Activation('relu'))

model.add(MaxPooling2D(pool_size=(2, 2)))
model.add(Dropout(0.5))

model.add(Flatten())
model.add(Dense(64))
model.add(Activation('relu'))
model.add(Dropout(0.5))

model.add(Dense(num_classes))
model.add(Activation('softmax'))

# sgd = SGD(lr=0.01, decay=1e-6, momentum=0.9, nesterov=True)
# model.compile(loss='categorical_crossentropy', optimizer=sgd,metrics=["accuracy"])
model.compile(loss='categorical_crossentropy', optimizer='sgd', metrics=["accuracy"])






# ---------------------------------------------------------------------------------
print("\n---------------> Training the model\n")
# ---------------------------------------------------------------------------------

hist = model.fit(X_train,
				 y_train,
				 batch_size=16,
				 nb_epoch=num_epoch,
				 verbose=1,
				 validation_data=(X_test, y_test))






# ---------------------------------------------------------------------------------
print("\n---------------> Evaluating the model\n")
# ---------------------------------------------------------------------------------

score = model.evaluate(X_test, y_test, show_accuracy=True, verbose=0)
print('Test Loss:', score[0])
print('Test accuracy:', score[1])

test_image = X_test[0:1]
print (test_image.shape)

print(model.predict(test_image))
print(model.predict_classes(test_image))
print(y_test[0:1])






# ---------------------------------------------------------------------------------
print("\n---------------> Testing the model\n")
# ---------------------------------------------------------------------------------

test_image = cv2.imread('test-eyes/hitoe-test/309.png')

# ----------------------------------------------------
# Comment, when RGB images
# ----------------------------------------------------
#test_image = cv2.cvtColor(test_image, cv2.COLOR_BGR2GRAY)
#test_image = cv2.resize(test_image, (100, 100))

test_image = np.array(test_image)
test_image = test_image.astype('float32')
test_image /= 255
print (test_image.shape)


if num_channel == 1:

	test_image = np.expand_dims(test_image, axis=3)
	test_image = np.expand_dims(test_image, axis=0)
	print (test_image.shape)

else:

	test_image = np.expand_dims(test_image, axis=0)
	print (test_image.shape)






# ---------------------------------------------------------------------------------
print("\n---------------> Prediction\n")
# ---------------------------------------------------------------------------------

print((model.predict(test_image)))
print(model.predict_classes(test_image))






# ---------------------------------------------------------------------------------
print("\n---------------> Saving the model\n")
# ---------------------------------------------------------------------------------

from keras.models import model_from_json
from keras.models import load_model

# serialize model to JSON
model_json = model.to_json()
with open("kerasEyesModel.json", "w") as json_file:
	json_file.write(model_json)

# serialize weights to HDF5
model.save_weights("kerasEyesModel.h5")
print("Saved model to disk")

# load json and create model
json_file = open('kerasEyesModel.json', 'r')
loaded_model_json = json_file.read()
json_file.close()
loaded_model = model_from_json(loaded_model_json)

# load weights into new model
loaded_model.load_weights("kerasEyesModel.h5")
print("Loaded model from disk")

model.save('kerasEyesModel.hdf5')
loaded_model = load_model('kerasEyesModel.hdf5')






# ---------------------------------------------------------------------------------
print("\n---------------> Converting to CoreML\n")
# ---------------------------------------------------------------------------------

import coremltools

# coreml_model = coremltools.converters.keras.convert(model)
# coreml_model.save("keras_mnist_4.mlmodel")

output_labels = ["Okubutae", "Futae", "Hitoe"]
scale = 1/255.0


coreml_model = coremltools.converters.keras.convert('/Work/MyProjects/Python/keras-eyes-recognition/kerasEyesModel.hdf5',
													input_names='image',
													image_input_names='image',
													output_names='output',
													class_labels= output_labels,
													image_scale=scale)


coreml_model.author = 'Jakub Tlach'
coreml_model.license = 'MIT'
coreml_model.short_description = 'Model to classify 3 types of the eyes'
coreml_model.input_description['image'] = 'RGB image of eyes'
coreml_model.output_description['output'] = 'Predicted type of the eyes'

coreml_model.save('kerasEyesModel.mlmodel')