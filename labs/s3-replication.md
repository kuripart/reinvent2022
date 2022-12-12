Implementing Multi-Region Backup with Amazon S3 Cross-Region Replication

Lab overview
Amazon Simple Storage Service (Amazon S3) is an object storage service built to store and retrieve any amount of data from anywhere on the Internet. It offers an extremely durable, highly available, and infinitely scalable data storage infrastructure at very low costs.

Amazon S3 supports Cross-Region Replication (CRR) for automatic, asynchronous copying of objects across buckets in different AWS Regions. Cross-Region Replication can help you:

Comply with compliance requirements — Although Amazon S3 stores your data across multiple geographically distant Availability Zones by default, compliance requirements might dictate that you store data at even greater distances. Cross-region replication allows you to replicate data between distant AWS Regions to satisfy these requirements.
Minimize latency — If your customers are in two geographic locations, you can minimize latency in accessing objects by maintaining object copies in AWS Regions that are geographically closer to your users.
Increase operational efficiency — If you have compute clusters in two different AWS Regions that analyze the same set of objects, you might choose to maintain object copies in those Regions.
Maintain object copies under different ownership — Regardless of who owns the source object you can tell Amazon S3 to change replica ownership to the AWS account that owns the destination bucket. This is referred to as the owner override option. You might use this option to restrict access to object replicas.
This lab demonstrates the process of configuring Cross-Region Replication (CRR) between two S3 buckets in separate regions.

TOPICS COVERED
By the end of this lab, you will be able to:

Create source and destination S3 buckets with versioning enabled.
Create a Cross-Region Replication policy.
Enable replication for an entire bucket, encrypted files, a specific folder, or a specific tag.
Identify the conditions necessary for replicating objects.
Delete replicated files and understand how deletions are replicated.
TECHNICAL KNOWLEDGE PREREQUISITES
To successfully complete this lab, you should be familiar with basic navigation of the AWS Management Console and Amazon S3 buckets.

Task 1: Create and configure source and destination buckets
Before Cross-Region Replication (CRR) can be enabled, you must first create the source and destination buckets. Versioning must be enabled for both buckets in order to configure CRR.

 Any objects that reside in the bucket before versioning is enabled will not be replicated. For more information about S3 Versioning, refer to How S3 Versioning works in the Additional resources section.

In this task, you create the source and destination buckets and enable versioning on each bucket.

TASK 1.1: CREATE THE SOURCE BUCKET
If you have not already done so, follow the steps in the Start Lab section to log into the AWS Management Console.

At the top of the page, in the unified search bar, search for and choose 

S3

On the Amazon S3 Buckets page, at the top-right corner, choose Create bucket

On the Create bucket page:

For Bucket name, enter the value of SourceBucket listed to the left of these instructions.
For AWS Region, select the value of PrimaryRegion listed to the left of these instructions.
Keep the remaining default values.
At the bottom of the page, choose Create bucket
TASK 1.2: ENABLE VERSIONING ON THE SOURCE BUCKET
On the Buckets page, choose the link for the source-bucket bucket.

On the source-bucket details page, choose the Properties tab.

In the Bucket Versioning section, choose Edit

On the Edit Bucket Versioning page:

For Bucket Versioning, select Enable.
At the bottom right-hand corner of the page, choose Save changes
You have now enabled versioning on the source bucket.

TASK 1.3: CREATE DESTINATION BUCKET AND ENABLE VERSIONING
Now that you have created the source bucket and enabled versioning on it, you create the destination bucket to replicate objects to. The destination bucket must have versioning enabled as well, but this time you enable it using the bucket creation wizard.

In the navigation breadcrumbs at the top of the page, choose the Amazon S3 link to return to the Buckets page.

On the Amazon S3 Buckets page, at the top-right corner, choose Create bucket

On the Create bucket page:

For Bucket name, enter the value of DestinationBucket listed to the left of these instructions.
For AWS Region, select the value of SecondaryRegion listed to the left of these instructions.
For Bucket Versioning, select Enable.
Keep the remaining default values.
At the bottom of the page, choose Create bucket

On the Buckets page, choose the link for the destination-bucket bucket.

Choose the Properties tab.

In the Bucket Versioning section, verify Bucket Versioning is set to Enabled.

Return to the S3 Buckets page.

 Congratulations! You have successfully created source and destination buckets and enabled versioning on each one.

Task 2: Enable Cross-Region Replication on a bucket
Now that you have created and configured the source and destination buckets, you can enable replication. Replication rules are used to determine which objects in a bucket are replicated. You can replicate an entire bucket, a specific folder within a bucket, or any objects with a specified tag. You can replicate objects to a bucket in the same or different regions. Since you are exploring Cross-Region Replication, you replicate to a different region.

 Objects that already exist in the bucket before replication is enabled will NOT be replicated. By default, only new objects uploaded to a bucket after replication is enabled are replicated. However, if you have a need to replicate existing objects, you can contact the AWS Support Center for assistance. For more information, refer to Replicating objects in the Additional resources section.

In this task, you create a replication policy to enable replication of an entire bucket. You then upload an object to the source bucket and verify that it is replicated to the destination bucket.

TASK 2.1: UPLOAD A FILE TO THE SOURCE BUCKET BEFORE ENABLING REPLICATION
First, upload a sample file to the source bucket to demonstrate how a replication policy does not apply to objects that exist in the bucket before creating the policy.

Download the following file to your device: pre-crr.txt

On the Buckets page, choose the link for the source-bucket bucket.

Choose Upload

Choose Add files

Browse to and select the pre-crr.txt file you downloaded previously.

At the bottom of the page, choose Upload

At the top of the page, you should receive a message that states  Upload succeeded

At the top right-hand corner of the page, choose Close
TASK 2.2: CREATE A REPLICATION RULE FOR THE ENTIRE BUCKET
On the source-bucket details page, choose the Management tab.

In the Replication rules section, choose Create replication rule

On the Create replication rule page:

In the Replication rule configuration section, for Replication rule name, enter 

crr-full-bucket
In the Source bucket section, for Choose a rule scope, select This rule applies to all objects in the bucket.
In the Destination section, for Destination, select Choose a bucket in this account.
For Bucket name, enter the value of DestinationBucket listed to the left of these instructions.
In the IAM role section, for IAM role, select S3-CRR-Role.
 The S3-CRR_Role IAM role grants permissions to the S3 service that allow it to perform Get, List, and Replicate operations on the source and destination buckets. The role looks similar to this, though the bucket names will differ:


{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetReplicationConfiguration",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::source-bucket-57538018"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObjectVersionForReplication",
                "s3:GetObjectVersionAcl",
                "s3:GetObjectVersionTagging"
            ],
            "Resource": [
                "arn:aws:s3:::source-bucket-57538018/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ReplicateObject",
                "s3:ReplicateDelete",
                "s3:ReplicateTags"
            ],
            "Resource": "arn:aws:s3:::destination-bucket-57538018/*"
        }
    ]
}
 For more information about the permissions required to enable replication, refer to Setting up permissions in the Additional resources section.

At the bottom of the page, choose Save
At the top of the page, you should receive a message that states  Replication configuration successfully updated

In the navigation breadcrumbs at the top of the page, choose the Amazon S3 link to return to the Buckets page.

Choose the link for the destination-bucket bucket.

Notice that the destination bucket is empty, even though replication is enabled and the source bucket contains a file. Only new files uploaded to the source bucket after replication is enabled will be replicated to the destination bucket.

TASK 2.3: UPLOAD A NEW FILE AND VERIFY IT REPLICATES SUCCESSFULLY
Download the following file to your device: crr-bucket.txt

In the navigation breadcrumbs at the top of the page, choose the Amazon S3 link to return to the Buckets page.

On the Buckets page, choose the link for the source-bucket bucket.

Choose Upload

Choose Add files

Browse to and select the crr-bucket.txt file you downloaded previously.

At the bottom of the page, choose Upload

At the top of the page, you should receive a message that states  Upload succeeded

At the top right-hand corner of the page, choose Close

In the navigation breadcrumbs at the top of the page, choose the Amazon S3 link to return to the Buckets page.

Choose the link for the destination-bucket bucket.

Notice that the destination bucket now contains the crr-bucket.txt file you uploaded to the source bucket.

 If no files are listed, wait a few seconds, and then choose the  refresh button above the list of objects. It may take a minute or two for the object to replicate.

 Congratulations! You have successfully configured Cross-Region Replication for an entire S3 bucket.

Task 3: Replicate encrypted files
In this task, you upload an encrypted object to an S3 bucket and validate whether or not it replicates using the destination bucket.

TASK 3.1: UPLOAD A KMS-ENCRYPTED FILE
Download the following file to your device: crr-encrypted.txt

In the navigation breadcrumbs at the top of the page, choose the Amazon S3 link to return to the Buckets page.

On the Buckets page, choose the link for the source-bucket bucket.

Choose Upload

Choose Add files

Browse to and select the crr-encrypted.txt file you downloaded previously.

At the bottom of the page, choose  Properties to expand it.

In the Server-side encryption settings section:

For Server-side encryption, select Specify an encryption key.
For Encryption key type, select AWS Key Management Service key (SSE-KMS).
For AWS KMS key, select AWS managed key (aws/s3).
At the bottom of the page, choose Upload
At the top of the page, you should receive a message that states  Upload succeeded

At the top right-hand corner of the page, choose Close

In the navigation breadcrumbs at the top of the page, choose the Amazon S3 link to return to the Buckets page.

Choose the link for the destination-bucket bucket.

Notice that the destination bucket does not contain a copy of the KMS encrypted file, even though replication is enabled for the entire source bucket. When you created the replication rule, you kept the default option for encryption, which is to not replicate KMS-encrypted files. Since the file you just uploaded is KMS-encrypted, it was not replicated to the destination bucket.

TASK 3.2: EDIT THE REPLICATION RULE
Next, edit the replication rule to allow replication of KMS-encrypted files.

In the navigation breadcrumbs at the top of the page, choose the Amazon S3 link to return to the Buckets page.

Choose the link for the source-bucket bucket.

On the source-bucket details page, choose the Management tab.

In the Replication rules section, select the crr-full-bucket rule you created previously, and then choose Edit rule

On the Edit replication rule page:

In the Encryption section, select Replicate objects encrypted with AWS KMS. Additional options appear.
For AWS KMS key for encrypting destination objects, select AWS managed key (aws/s3).
At the bottom of the page, choose Save
At the top of the page, you should receive a message that states  Replication configuration successfully updated

 Changes to replication rules only affect objects that are uploaded after you change the rule. Next, upload the encrypted file again to invoke the replication rule.

TASK 3.3: TEST THE ENCRYPTED FILE REPLICATION RULE
In the navigation breadcrumbs at the top of the page, choose the source-bucket link to return to the source-bucket details page.

Choose Upload

Choose Add files

Browse to and select the crr-encrypted.txt file you downloaded previously.

At the bottom of the page, choose  Properties to expand it.

In the Server-side encryption settings section:

For Server-side encryption, select Specify an encryption key.
For Encryption key type, select AWS Key Management Service key (SSE-KMS).
For AWS KMS key, select AWS managed key (aws/s3).
At the bottom of the page, choose Upload
At the top of the page, you should receive a message that states  Upload succeeded

At the top right-hand corner of the page, choose Close

In the navigation breadcrumbs at the top of the page, choose the Amazon S3 link to return to the Buckets page.

Choose the link for the destination-bucket bucket.

Notice that the destination bucket now contains the crr-encrypted.txt file you uploaded to the source bucket.

 If the expected files are not listed, wait a few seconds, and then choose the  refresh button above the list of objects.

 For more information about replicating encrypted objects, refer to Replicating objects created with server-side encryption (SSE) using AWS KMS CMKs in the Additional resources section.

 Congratulations! You have successfully configured a replication rule to allow for replication of KMS-encrypted files and verify the encrypted file was replicated.

Task 4: Configure replication of a single folder
In Amazon S3, folders are considered prefixes. For example, a folder in your S3 bucket named Source would be a prefix notated as Source/. A file inside that folder would be notated as Source/File.

In this task, you create a replication policy based on a prefix to replicate only objects in the specified folder. Choosing a folder to replicate allows you to replicate a specific set of objects easily, rather than an entire bucket.

TASK 4.1: CREATE A FOLDER IN THE SOURCE BUCKET
In the navigation breadcrumbs at the top of the page, choose the Amazon S3 link to return to the Buckets page.

On the Buckets page, choose the link for the source-bucket bucket.

Choose Create folder

On the Create folder page:

For Folder name, enter 

crr-test
At the bottom of the page, choose Create folder
TASK 4.2: DELETE THE CURRENT REPLICATION POLICY
Next, delete the replication policy you created previously so it does not override the policy you create in an upcoming task.

On the source-bucket details page, choose the Management tab.

In the Replication rules section, select the crr-full-bucket rule you created previously, and then choose Delete

In the Delete replication rule? pop-up window, choose Delete replication rule

TASK 4.3: CREATE A REPLICATION RULE FOR A SINGLE FOLDER
On the source-bucket details page, in the Replication rules section, choose Create replication rule

On the Create replication rule page:

In the Replication rule configuration section, for Replication rule name, enter 

crr-folder-only
In the Source bucket section, for Choose a rule scope, select Limit the scope of this rule using one or more filters.
For Prefix, enter 

crr-test/
In the Destination section, for Destination, select Choose a bucket in this account.
For Bucket name, enter the value of DestinationBucket listed to the left of these instructions.
In the IAM role section, for IAM role, select S3-CRR-Role.
At the bottom of the page, choose Save
At the top of the page, you should receive a message that states  Replication configuration successfully updated

TASK 4.4: TEST THE FOLDER REPLICATION RULE
Download the following files to your device:
crr-folder.txt
crr-folder-root.txt
In the navigation breadcrumbs at the top of the page, choose the source-bucket link to return to the source-bucket details page.
First, upload a sample file to the root of the bucket.

Choose Upload

Choose Add files

Browse to and select the crr-folder-root.txt file you downloaded previously.

At the bottom of the page, choose Upload

At the top of the page, you should receive a message that states  Upload succeeded

At the top right-hand corner of the page, choose Close
Next, upload a file to the crr-test folder.

Choose the link for the crr-test folder.

Choose Upload

Choose Add files

Browse to and select the crr-folder.txt file you downloaded previously.

At the bottom of the page, choose Upload

At the top of the page, you should receive a message that states  Upload succeeded

At the top right-hand corner of the page, choose Close
Now that you have uploaded the two sample files, verify that the replication has taken place according to the replication rule you created.

In the navigation breadcrumbs at the top of the page, choose the Amazon S3 link to return to the Buckets page.

On the Buckets page, choose the link for the destination-bucket bucket.

You should see three objects listed in the bucket:

 crr-bucket.txt
 crr-encrypted.txt
 crr-test/
Notice that the crr-folder-root.txt file that you uploaded to the root of the source bucket was not replicated to the destination bucket.

Choose the link for the crr-test folder.
You should see the crr-folder.txt file you uploaded to the crr-test folder in the source bucket.

 If the expected files are not listed, wait a few seconds, and then choose the  refresh button above the list of objects.

 Congratulations! You have successfully configured Cross-Region Replication for a single folder within an S3 bucket.

Task 5: Configure replication using tags
Tags can be used to identify specific objects to replicate, rather than replicating the entire bucket or folder.

In this task, you create a replication rule to replicate any object with a specific tag.

 Much like versioning, objects with tags must be uploaded to the source bucket after the replication policy using tags has been created and enabled. Objects that are uploaded and tagged prior to the policy being created will not replicate.

TASK 5.1: DELETE THE CURRENT REPLICATION POLICY
First, delete the replication policy you created previously so it does not override the policy you create in an upcoming task.

In the navigation breadcrumbs at the top of the page, choose the Amazon S3 link to return to the Buckets page.

On the Buckets page, choose the link for the source-bucket bucket.

On the source-bucket details page, choose the Management tab.

In the Replication rules section, select the crr-folder-only rule you created previously, and then choose Delete

In the Delete replication rule? pop-up window, choose Delete replication rule

TASK 5.2: CREATE A REPLICATION RULE FOR TAGGED OBJECTS
On the source-bucket details page, in the Replication rules section, choose Create replication rule

On the Create replication rule page:

In the Replication rule configuration section, for Replication rule name, enter 

crr-tag-only
In the Source bucket section, for Choose a rule scope, select Limit the scope of this rule using one or more filters.
For Tags, choose Add tag A new set of fields appears.
For Key, enter 

replicate
For Value, enter 

yes
 Tag keys and values are case sensitive. For more information about tags, refer to Tagging AWS Resources in the Additional resources section.

In the Destination section, for Destination, select Choose a bucket in this account.
For Bucket name, enter the value of DestinationBucket listed to the left of these instructions.
In the IAM role section, for IAM role, select S3-CRR-Role.
At the bottom of the page, choose Save
At the top of the page, you should receive a message that states  Replication configuration successfully updated

TASK 5.3: TEST THE TAG REPLICATION RULE
Download the following files to your device:
crr-no-tag.txt
crr-tag.txt
In the navigation breadcrumbs at the top of the page, choose the source-bucket link to return to the source-bucket details page.
First, upload a sample file that is not tagged.

On the source-bucket details page, choose Upload

Choose Add files

Browse to and select the crr-no-tag.txt file you downloaded previously.

At the bottom of the page, choose Upload

At the top of the page, you should receive a message that states  Upload succeeded

At the top right-hand corner of the page, choose Close
Next, upload a sample file that is tagged.

Choose Upload

Choose Add files

Browse to and select the crr-tag.txt file you downloaded previously.

At the bottom of the page, choose  Properties to expand it.

In the Tags section, choose Add tag and then:

For Key, enter 

replicate
For Value, enter 

yes
At the bottom of the page, choose Upload
At the top of the page, you should receive a message that states  Upload succeeded

At the top right-hand corner of the page, choose Close
Now that you have uploaded the two sample files, verify that the replication has taken place according to the replication rule you created.

In the navigation breadcrumbs at the top of the page, choose the Amazon S3 link to return to the Buckets page.

On the Buckets page, choose the link for the destination-bucket bucket.

You should see four objects listed in the bucket:

 crr-bucket.txt
 crr-encrypted.txt
 crr-tag.txt
 crr-test
Notice that the crr-tag.txt file that you tagged was replicated to the destination bucket. However, the crr-no-tag.txt file that you did not tag was not replicated.

 If the expected files are not listed, wait a few seconds, and then choose the  refresh button above the list of objects.

 Congratulations! You have successfully configured Cross-Region Replication for tagged objects within an S3 bucket.

Task 6: Deleting replicated files
To protect against malicious intent and accidental deletion, object deletions that occur in a source bucket are not replicated to the destination bucket by default.

In this task, you delete a file that has been replicated and then observe the results.

In the navigation breadcrumbs at the top of the page, choose the Amazon S3 link to return to the Buckets page.

On the Buckets page, choose the link for the source-bucket bucket.

On the source-bucket details page, select the crr-tag.txt object, and then choose Delete

On the Delete objects page:

For Delete objects?, enter 

delete
At the bottom of the page, choose Delete objects

At the top right-hand corner of the page, choose Close

 When you delete an object in a versioning-enabled S3 bucket, the object is not actually deleted. Instead, a delete marker is created as the latest version of the object. For more information, refer to Working with delete markers in the Additional resources section.

Verify the crr-tag.txt file has been deleted from the source bucket.

In the navigation breadcrumbs at the top of the page, choose the Amazon S3 link to return to the Buckets page.

On the Buckets page, choose the link for the destination-bucket bucket.

You should notice that the crr-tag.txt file still exists in the destination bucket.

 If you have a business requirement to replicate deleted objects, you can modify your replication rule to enable Delete marker replication. For more information, refer to Replicating delete markers between buckets in the Additional resources section.

 Congratulations! You have discovered that deleting an object from a source bucket does not delete it from the destination bucket.

Conclusion
 Congratulations! You now have successfully:

Configured S3 buckets for versioning.
Created S3 Cross-Region Replication rules.
Replicated objects with rules for full buckets, encrypted files, folders, and tags.
Observed how the replication of deletions is handled.
Additional resources
Amazon S3 Cross-Region Replication
How S3 Versioning works
Replicating objects
Setting up permissions
Replicating objects created with server-side encryption (SSE) using AWS KMS CMKs
Tagging AWS resources
Working with delete markers
Replicating delete markers between buckets
