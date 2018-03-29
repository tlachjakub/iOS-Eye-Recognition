import coremltools


output_labels = ["Okubutae", "Futae", "Hitoe"]
scale = 1/255.0


coreml_model = coremltools.converters.keras.convert('./kerasEyesModel.hdf5',
													input_names='image',
													image_input_names='image',
													output_names='output',
													class_labels= output_labels,
													image_scale=scale)


coreml_model.author = 'Jakub Tlach'
coreml_model.license = 'MIT'
coreml_model.short_description = 'Model to classify 3 types of the eyes'
coreml_model.input_description['image'] = 'Grayscale image of eyes'
coreml_model.output_description['output'] = 'Predicted type of the eyes'

coreml_model.save('kerasEyesModel.mlmodel')