library("data.table")

# download, unzip and load the dataset

url = "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
f <- "Dataset.zip"
if (!file.exists(f)) {
	download.file(url, f)
	unzip(f)
	}

subjectTrain = fread("UCI HAR Dataset/train/subject_train.txt", col.names = "subject")
xTrain = fread("UCI HAR Dataset/train/X_train.txt")
yTrain = fread("UCI HAR Dataset/train/Y_train.txt", col.names="activity")

subjectTest = fread("UCI HAR Dataset/test/subject_test.txt", col.names = "subject")
xTest = fread("UCI HAR Dataset/test/X_test.txt")
yTest = fread("UCI HAR Dataset/test/Y_test.txt", col.names="activity")

activityLabels = fread("UCI HAR Dataset/activity_labels.txt")
featureLabels = fread("UCI HAR Dataset/features.txt")

# combine all test and training data

subjectComb <- rbind(subjectTrain, subjectTest)
yComb <- rbind(yTrain, yTest)

xComb <- rbind(xTrain, xTest)
names(xComb) <- featureLabels$V2

mergedData <- cbind(subjectComb, yComb, xComb)

# extract only the means & standard deviations by searching for mean() and std() in the column names and subsetting
a <- grepl("mean\\(\\)|std\\(\\)", names(mergedData))
a[1] = TRUE; a[2] = TRUE;
extractedMeanSd <- subset(mergedData, select = a)

# convert the activity numbers to the activity name
extractedMeanSd$activity = as.factor(activityLabels$V2[extractedMeanSd$activity])

# now we create the new dataset
newDs <- aggregate(.~activity+subject, orderedDs, mean)

# now we rename the new variables in this dataset to more descriptive names
tempNames <- sub("Acc", "Accelerometer", names(newDs))
tempNames <- sub("Gyro", "Gyroscope", tempNames)
tempNames <- sub("-mean\\(\\)","Mean", tempNames)
tempNames <- sub("-std\\(\\)","SD", tempNames)
tempNames <- sub("Mag","Magnitude", tempNames)
tempNames <- sub("^t", "time", tempNames)
tempNames <- sub("^f", "fourier", tempNames)
tempNames <- sub("BodyBody", "Body", tempNames)
names(newDs) <- tempNames

# write out the new data frame to disk as a .csv file
write.table(newDs, "run_analysis.csv", sep=",", qmethod="double", row.names = FALSE)