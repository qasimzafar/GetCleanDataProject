### Course Project - Getting and Cleaning Data | CodeBook

## Introduction

This codebook indicates all the variables and summaries calculated, along with units, and any other relevant information for the course project for Getting and Cleaning Data

The purpose of this project is to demonstrate your ability to collect, work with, and clean a data set. The goal is to prepare tidy data that can be used for later analysis. You will be graded by your peers on a series of yes/no questions related to the project. You will be required to submit: 1) a tidy data set as described below, 2) a link to a Github repository with your script for performing the analysis, and 3) a code book that describes the variables, the data, and any transformations or work that you performed to clean up the data called CodeBook.md. You should also include a README.md in the repo with your scripts. This repo explains how all of the scripts work and how they are connected.

One of the most exciting areas in all of data science right now is wearable computing. Companies like Fitbit, Nike, and Jawbone Up are racing to develop the most advanced algorithms to attract new users. The data linked to from the course website represent data collected from the accelerometers from the Samsung Galaxy S smartphone. A full description is available at the site where the data was obtained:

[http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones]

Here are the data for the project:

[https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip]

## Objective

The objective is to create one R script called run_analysis.R that does the following:

* Merges the training and the test sets to create one data set.
* Extracts only the measurements on the mean and standard deviation for each measurement.
* Uses descriptive activity names to name the activities in the data set
* Appropriately labels the data set with descriptive variable names.
* From the data set in step 4, creates a second, independent tidy data set with the average of each variable for each activity and each subject.

## Overview of the Data

*	Human Activity Recognition database built from the recordings of 30 subjects performing activities of daily living (ADL) while carrying a waist-mounted smartphone with embedded inertial sensors.
*	Number of Measurements: 10299
*	Number of Attributes Measured: 561

## Summary of Data Collection Mechanism

* The experiments have been carried out with a group of 30 volunteers within an age bracket of 19-48 years
* Each person performed six activities (WALKING, WALKING_UPSTAIRS, WALKING_DOWNSTAIRS, SITTING, STANDING, LAYING) wearing a smartphone (Samsung Galaxy S II) on the waist
* Using the smartphone's embedded accelerometer and gyroscope, 3-axial linear acceleration and 3-axial angular velocity at a constant rate of 50Hz was captured
* The experiments have been video-recorded to label the data manually
* The obtained dataset has been randomly partitioned into two sets, where 70% of the volunteers was selected for generating the training data and 30% the test data.

## Review Criteria

1.    The submitted data set is tidy.
2.    The Github repo contains the required script.
3.    GitHub contains a code book that indicates all the variables and summaries calculated, along with units, and any other relevant information.
4.    The README that explains the analysis files is clear and understandable.
5.    The work submitted for this project is the work of the student who submitted it.

## Objectives

# 1. Getting the Data

The script downloads the zip file from the link provided (if it has not already done so), and unzips it

```
library("data.table")

# download, unzip and load the dataset
url = "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
f <- "Dataset.zip"
if (!file.exists(f)) {
	download.file(url, f)
	unzip(f)
	}
```

# 2. Reading in the Data

The script reads in the relevant .txt files (the X, Y, and subject files from both the training and test folders). It automatically sets the column names for the subject and Y files for ease of use.

```
subjectTrain = fread("UCI HAR Dataset/train/subject_train.txt", col.names = "subject")
xTrain = fread("UCI HAR Dataset/train/X_train.txt")
yTrain = fread("UCI HAR Dataset/train/Y_train.txt", col.names="activity")

subjectTest = fread("UCI HAR Dataset/test/subject_test.txt", col.names = "subject")
xTest = fread("UCI HAR Dataset/test/X_test.txt")
yTest = fread("UCI HAR Dataset/test/Y_test.txt", col.names="activity")

activityLabels = fread("UCI HAR Dataset/activity_labels.txt")
featureLabels = fread("UCI HAR Dataset/features.txt")
```

# 3. Combining Data

From observation, it is immediately apparent that the X, Y and subject data are subsets of the same data. Their dimensions lead to the conclusion that they should be row-appended.

```
subjectComb <- rbind(subjectTrain, subjectTest)
yComb <- rbind(yTrain, yTest)
xComb <- rbind(xTrain, xTest)
```

The featureLabels frame contains the labels for the measured features (the xComb variable), so the names for the frame are set
```
names(xComb) <- featureLabels$V2
```

Note that the activity type (Y) and the subject id (subject) are single columns that should be appended to the measurements data frame, so use cbind

```
mergedData <- cbind(subjectComb, yComb, xComb)
```

# 4. Extracting Only Mean and Standard Deviation Variables

Search among the column names for the strings "mean()" and "std()", and subset them out. We make sure to include the first two columns (activity and subject) that we previously appended.

```
# extract only the means & standard deviations by searching for mean() and std() in the column names and subsetting
a <- grepl("mean\\(\\)|std\\(\\)", names(mergedData))
a[1] = TRUE; a[2] = TRUE;
extractedMeanSd <- subset(mergedData, select = a)
```

# 5. Adding Descriptive Names to the Activity Column Values

Each activity number (1 - 6) corresponds to the index of that activity in the activityLabels frame. Using this information, set the names of the dataset by replacing the number with the name of the activity

```
# convert the activity numbers to the activity name
extractedMeanSd$activity = as.factor(activityLabels$V2[extractedMeanSd$activity])
```

Only one step is left now in tidying this dataset - cleaning up making the variable names descriptive.

# 6. Obtaining the Averages

To obtain the averages of each measurement for each activity by each user, aggregate gives a one-line solution
```
# now we create the new dataset
newDs <- aggregate(.~activity+subject, orderedDs, mean)
```

This dataset still has untidy and confusing variable names.

# 7. Making Variable Names Descriptive

From the accompanying `features_info.txt` file in the dataset, note the following points regarding the variable names:

- Acc stands for Accelerometer
- Gyro stands for Gyroscope
- '-mean()' stands for Mean
- '-std()' stands for Standard Deviation
- Mag stands for Magnitude
- The word Body is repeated in a few variables e.g. `fBodyBodyGyroMag-mean()`
- Time-domain variables are prefixed by 't', and frequency-domain variables are prefixed by 'f'

Bringing all of this together:

1. Replace the abbreviations with full names
2. Replace '-mean()' and '-std()' with the more descriptive Mean and SD
3. Remove the word Body from the variable names wherever it is duplicated
4. Prefix time-domain variables by 'time' and Fourier-transformed frequency-domain variables by 'fourier'

The code for the above corrective measures:

```
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
```
This is now a tidy dataset.


# 8. Saving the New Dataset

Write out the obtained dataset using `write.table`, to the file `run_analysis.csv` which is included in the root of this repo.

```
# write out the new data frame to disk as a .csv file
write.table(newDs, "run_analysis.csv", sep=",", qmethod="double", row.names = FALSE)
```

This concludes the manipulations required to obtain the raw dataset from the internet, tidy it, extract variables of interest and store them in a separate, attached file.