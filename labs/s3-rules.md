My Bucket, My Rules

Lab overview
With more than 100 trillion objects in Amazon Simple Storage Service (Amazon S3) and an almost unimaginably broad set of use cases, securing data stored in Amazon S3 is important for every organization.

You’re the bucket owner and you want to ensure that the bucket and its contents are compliant with the security guidelines and compliance regulations of your organization. This lab will demonstrate some examples of Amazon S3 preventative security best practices. Its goal is to provide you with the skills that you need to successfully configure and test policies to enforce the following:

Where the bucket is accessed from
Access permissions
Encryption at rest and in transit
The type of encryption that is required for compliance
OBJECTIVES
By the end of this lab, you will be able to do the following:

Configure the bucket policy to enforce HTTPS connections only.
Configure the bucket policy to accept connections only through the virtual private cloud (VPC) endpoint.
Configure bucket policy to only accept object uploads that use an accepted encryption method and encryption key.
Test these requirements using the AWS Command Line Interface (AWS CLI).
PREREQUISITES
This lab requires the following:

Access to a computer with Windows, macOS X, or Linux (Ubuntu, SuSE, or Red Hat)
A modern internet browser such as Google Chrome or Mozilla Firefox
TECHNICAL KNOWLEDGE PREREQUISITES
To successfully complete this lab, you should be familiar with the following services or features:

Amazon S3
AWS Identity and Access Management (IAM)
Amazon Virtual Private Cloud (Amazon VPC)
VPC gateway endpoints
AWS Key Management Service (AWS KMS)

LAB SCENARIO
The initial lab setup has the following components:

An S3 bucket.
One VPC with one public subnet and one private subnet.
The public subnet has direct access to the internet through the internet gateway.
The private subnet has access to Amazon S3 through a VPC gateway endpoint.
One EC2 instance in each subnet.
The EC2 instances have permissions to list, put, and get objects from the S3 bucket through an Amazon EC2 IAM role.
Two AWS KMS keys.
 Note: The Resources pane to the left of these instructions includes a list of all the lab components that you need through the lab activities.

The following diagram shows the lab environment at the start of the lab:

Initial deploy

Task 1: Testing Amazon S3 connectivity and uploading test objects
In this task, you perform the following:

Connect to both the public and private instances through Session Manager, a capability of AWS Systems Manager.
Set Linux variables on both instances that you use in your AWS CLI commands.
Run some AWS CLI commands to verify access to the lab bucket.
Upload a test object to the bucket.
Check the current bucket policy settings on the lab bucket.
 Hint: Throughout the lab, you use the terminal to run AWS CLI commands for both public and private instances. Make sure that you open each terminal on a separate browser tab. Also, before you run a command, double-check that you are using the correct terminal (whether for the public or private instance).

To connect to the Public-Instance terminal, copy SessionManagerPublicInstanceUrl from the Resources pane to the left of these instructions, and then open this URL on a new browser tab. This will open the Public-Instance terminal with the Public-Instance$ shell prompt.

 Command: To create an object on the instance to be used for testing, run the following command on the Public-Instance:

Public-Instance$


echo 'This is the 1st test object for the lab' > object01.txt
 Expected output:

None, unless there is an error.

 Command: To set these variables by replacing the values from the Resources pane to the left of these instructions, run the following commands:
 Copy command: You might want to copy these commands to your preferred note editor, update the values, and then paste them back into the terminal.

Public-Instance$


lab_bucket=REPLACE_WITH_YOUR_LabBucketName
lab_region=REPLACE_WITH_YOUR_AwsRegionCode
 Expected output:

None, unless there is an error.

 Command: To verify that the variables are set correctly, run the following commands, and validate the output:
Public-Instance$


echo $lab_bucket
echo $lab_region
 Expected output:


******************************
**** This is OUTPUT ONLY. ****
******************************

Public-Instance$ echo $lab_bucket
mybucketlab-random_number
Public-Instance$ echo $lab_region
us-east-1
 Hint:

In this lab, you run many commands from the command line interface (CLI) after replacing some parameters in the sample command, such as the bucket name and other attributes. You set some variables in this section, which simplifies copying the commands into your Amazon EC2 terminal.
If your session terminates, you need to set these variables again.
In each task, we show the command using the variables you set so that you can directly copy them into your terminal. The command should work if the variables are set correctly.
 Command: To upload the object that you created into the bucket, run the following command:
Public-Instance$


aws --endpoint-url https://s3.$lab_region.amazonaws.com s3api put-object \
--bucket $lab_bucket \
--body object01.txt \
--key object01.txt
 Expected output:


******************************
**** This is OUTPUT ONLY. ****
******************************

{
    "SSEKMSKeyId": "arn:aws:kms:us-east-1:111122223333:key/1c446a23-24aa-4388-8f0f-0ff2f5b37c86",
    "ETag": "\"f9a29703c427f46f94fd76e5baf2222f\"",
    "ServerSideEncryption": "aws:kms"
}
The output indicates that the upload was successful.

 Command: To list the objects in the buckets, run the following command:
Public-Instance$


aws --endpoint-url https://s3.$lab_region.amazonaws.com s3api list-objects --bucket $lab_bucket
 Expected output:


******************************
**** This is OUTPUT ONLY. ****
******************************

{
    "Contents": [
        {
            "LastModified": "2022-09-12T02:20:00.000Z",
            "ETag": "\"f9a29703c427f46f94fd76e5baf2222f\"",
            "StorageClass": "STANDARD",
            "Key": "object01.txt",
            "Size": 40
        }
    ]
}
You should be able to see the contents in the bucket.

To connect to the Private-Instance terminal, copy SessionManagerPrivateInstanceUrl from the Resources pane to the left of these instructions and open this URL on a new browser tab. This will open the Private-Instance terminal with the Private-Instance$ shell prompt.
 Note: Make sure that you differentiate between the terminals of the public and private instance and that you enter the commands in the correct terminal.

 Command: To set the variables on the private instance by replacing the values from the Resources pane to the left of these instructions, run the following commands:
 Copy command: You might want to copy these commands to your preferred note editor, update the values, and then paste back into the terminal.

Private-Instance$


lab_bucket=REPLACE_WITH_YOUR_LabBucketName
lab_region=REPLACE_WITH_YOUR_AwsRegionCode
kms_green_key_id=REPLACE_WITH_YOUR_KMSGreenKeyID
kms_red_key_id=REPLACE_WITH_YOUR_KMSRedKeyID
 Expected output:

None, unless there is an error.

 Hint:

In this lab, you run many commands from the CLI after replacing some parameters in the sample command, such as bucket name and other attributes. You set some variables in this section, which simplifies copying the commands into your Amazon EC2 terminal.
If your session terminates, you need to set these variables again.
In each task, we show the command using the variables that you set, so you can directly copy them into your terminal. The command should work if the variables are set correctly.
 Command: To verify that the variables are set correctly, run the following commands and validate the output:
Private-Instance$


echo $lab_bucket
echo $lab_region
echo $kms_green_key_id
echo $kms_red_key_id
 Expected output:


******************************
**** This is OUTPUT ONLY. ****
******************************

Private-Instance$ echo $lab_bucket
mybucketlab-random_number
Private-Instance$ echo $lab_region
us-east-1
Private-Instance$ echo $kms_green_key_id
1c446a23-24aa-4388-8f0f-0ff2f5b37c86
Private-Instance$ echo $kms_red_key_id
30892466-ed5b-4f32-9a0d-fd8e344421fd
 Command: To list the objects in the bucket, run the following command:
Private-Instance$


aws --endpoint-url https://s3.$lab_region.amazonaws.com s3api list-objects --bucket $lab_bucket
 Expected output:


******************************
**** This is OUTPUT ONLY. ****
******************************

{
    "Contents": [
        {
            "LastModified": "2022-09-12T02:20:00.000Z",
            "ETag": "\"f9a29703c427f46f94fd76e5baf2222f\"",
            "StorageClass": "STANDARD",
            "Key": "object01.txt",
            "Size": 40
        }
    ]
}
You should be able to see the contents in the bucket. This indicates that you can connect to the bucket through the gateway VPC endpoint, which was created as part of the pre-lab build.

In the AWS Management Console, use the AWS search bar to search for 

S3
 and then, in the list of results, choose the service.

In the Amazon S3 console, under Buckets, locate where the buckets are listed and choose the mybucketlab-<RANDOM_NUMBER> link for your bucket.

Choose the Permissions tab, scroll down to the Bucket Policy section and check the current bucket policy. Notice that the policy is empty. This means that all permissions are now controlled through the IAM policy on the identity that makes the API calls (EC2 instances in this scenario).

In the next few tasks of this lab, you start configuring your bucket policy to enforce certain requirements for accessing your bucket.

 Congratulations! You verified that you can connect to the lab bucket from both instances, set Linux variables, uploaded a test object, and verified that the bucket has no bucket policy applied to it.

Task 2: Enforcing HTTPS connections
In this task, you perform the following:

Test accessing the bucket using HTTP instead of HTTPS.
Configure a bucket policy to restrict access to the bucket using only HTTPS and verify it.
In the previous task, you used the HTTPS endpoint when making the API calls from the AWS CLI. So, the calls were made using HTTPS on TCP port 443. If the endpoint supports HTTP, you can use HTTP calls by choosing the protocol in the request.

 Command: To test if you can make HTTP calls to the bucket from Public-Instance, run the following command:
Public-Instance$


aws --endpoint-url http://s3.$lab_region.amazonaws.com s3api list-objects --bucket $lab_bucket
 Expected output:


******************************
**** This is OUTPUT ONLY. ****
******************************

{
    "Contents": [
        {
            "LastModified": "2022-09-12T02:20:00.000Z",
            "ETag": "\"f9a29703c427f46f94fd76e5baf2222f\"",
            "StorageClass": "STANDARD",
            "Key": "object01.txt",
            "Size": 40
        }
    ]
}
You should be able to see the contents in the bucket.

 Command: To test if you can make HTTP calls to the bucket from Private-Instance, run the following command:
Private-Instance$


aws --endpoint-url http://s3.$lab_region.amazonaws.com s3api list-objects --bucket $lab_bucket
 Expected output:


******************************
**** This is OUTPUT ONLY. ****
******************************

{
    "Contents": [
        {
            "LastModified": "2022-09-12T02:20:00.000Z",
            "ETag": "\"f9a29703c427f46f94fd76e5baf2222f\"",
            "StorageClass": "STANDARD",
            "Key": "object01.txt",
            "Size": 40
        }
    ]
}
You should be able to see the contents in the bucket.

Both instances should be able to use HTTP calls as there is no HTTPS enforcement configured yet.

 Note: Some AWS services do not support HTTP. For more information on service endpoint protocol support, see Service Endpoints and Quotas.
For compliance reasons, you need to ensure that only HTTPS connections are allowed to the bucket (encryption in transit). As the bucket owner, you can only control your bucket policy and have no control over the instances policies or applications.

Do it yourself

Configure a bucket policy on your bucket to deny any connections that do not use HTTPS. The bucket policy must deny all Amazon S3 actions to the bucket and its objects from any principal if HTTP protocol is used. You need to find a suitable IAM condition that helps you achieve your goal.
For hints on how to complete this task, see What S3 Bucket Policy Should I Use to Comply with the AWS Config Rule S3-bucket-ssl-requests-only?.

If you get stuck

For the full solution, in the Solutions section, see Task 2 solution .

Now, verify that the bucket policy that you configured is correct.

 Command: To test if you can make HTTPS calls to the bucket from Public-Instance, run the following command:
Public-Instance$


aws --endpoint-url https://s3.$lab_region.amazonaws.com s3api list-objects --bucket $lab_bucket
 Expected output:


******************************
**** This is OUTPUT ONLY. ****
******************************

{
    "Contents": [
        {
            "LastModified": "2022-09-12T02:20:00.000Z",
            "ETag": "\"f9a29703c427f46f94fd76e5baf2222f\"",
            "StorageClass": "STANDARD",
            "Key": "object01.txt",
            "Size": 40
        }
    ]
}
This should be successful, and you can view the contents in the bucket because the call was made using HTTPS.

 Command: To test if you can make HTTP calls to the bucket from Public-Instance, run the following command:
Public-Instance$


aws --endpoint-url http://s3.$lab_region.amazonaws.com s3api list-objects --bucket $lab_bucket
 Expected output:


******************************
**** This is OUTPUT ONLY. ****
******************************

An error occurred (AccessDenied) when calling the ListObjects operation: Access Denied
This should be denied if your bucket policy is correct because it used HTTP.

 Command: To test if you can make HTTPS calls to the bucket from Private-Instance, run the following command:
Private-Instance$


aws --endpoint-url https://s3.$lab_region.amazonaws.com s3api list-objects --bucket $lab_bucket
 Expected output:


******************************
**** This is OUTPUT ONLY. ****
******************************

{
    "Contents": [
        {
            "LastModified": "2022-09-12T02:20:00.000Z",
            "ETag": "\"f9a29703c427f46f94fd76e5baf2222f\"",
            "StorageClass": "STANDARD",
            "Key": "object01.txt",
            "Size": 40
        }
    ]
}
This should be successful, and you can view the contents in the bucket because the call was made using HTTPS.

 Command: To test if you can make HTTP calls to the bucket from Private-Instance, run the following command:
Private-Instance$


aws --endpoint-url http://s3.$lab_region.amazonaws.com s3api list-objects --bucket $lab_bucket
 Expected output:


******************************
**** This is OUTPUT ONLY. ****
******************************

An error occurred (AccessDenied) when calling the ListObjects operation: Access Denied
This should be denied if your bucket policy is correct because it used HTTP.

 Congratulations! You have applied your first bucket rule of your compliance requirements on your bucket and restricted access to the bucket to HTTPS only and validated it.

Task 3: Enforcing access to the bucket through the VPC endpoint
In this task, you perform the following:

Add a second statement to your bucket policy to restrict bucket access to be only through the private subnet and specifically, the VPC gateway endpoint.
Validate that the bucket policy is correct.
At the moment, the S3 bucket is accessed from both the public and private instances using different paths:

The public instance is accessing Amazon S3 through the internet gateway.
The private instance is accessing the Amazon S3 AWS network, without the need for internet or network address translation (NAT) gateways.
Your lab setup already has a configured VPC endpoint (gateway endpoint) in the private subnet, which provided the private instance with access to the bucket in the previous tasks.

 Note: For more information on VPC gateway endpoints, see Gateway Endpoints.
Based on compliance requirements, you want to restrict the access to the bucket to be only through the private subnet and specifically, through the VPC gateway endpoint. Because you don’t have access or control over the VPC configuration, you need to enforce this requirement on your bucket using the bucket policy.

Do it yourself

Modify your bucket policy by adding a new statement that denies any connections that do not originate in the Amazon S3 gateway endpoint in the private subnet. You can find the Amazon S3 gateway endpoint VPC endpoint ID on the Resources tab to the left of these instructions. You need to find a suitable IAM condition that helps you achieve your goal. Read the following CAUTION before you configure the policy:
 CAUTION: Follow these guidelines in your bucket policy statement:

Ensure that you only include these Actions in your bucket policy statement:

s3:GetObject
s3:PutObject
s3:ListBucket
Do not use a wildcard “*” for the actions because you might lock yourself completely out of the bucket.

For this specific statement, use the Amazon EC2 role Amazon Resource Name (ARN) value as the principal instead of the wildcard principal “*”. By doing so, you can continue browsing the bucket objects from the console and checking their properties, which you will need later. You can find the Amazon EC2 role ARN on the Resources tab to the left of these instructions. For more information on how to use the role as a principal, see “IAM role principals” at AWS JSON Policy Elements: Principal.

For hints on how to complete this task, see Controlling Access from VPC Endpoints with Bucket Policies.

If you get stuck

For the full solution, in the Solutions section, see Task 3 solution .

Now, verify that the bucket policy that you configured is correct.

Testing from Public-Instance

 Command: To test if you can list the bucket objects from Public-Instance, run the following command:
Public-Instance$


aws --endpoint-url https://s3.$lab_region.amazonaws.com s3api list-objects --bucket $lab_bucket
 Expected output:


******************************
**** This is OUTPUT ONLY. ****
******************************

An error occurred (AccessDenied) when calling the ListObjects operation: Access Denied
 Command: To test if you can put an object to the bucket from Public-Instance (by uploading the same file but with a new object name), run the following command:
Public-Instance$


aws --endpoint-url https://s3.$lab_region.amazonaws.com s3api put-object \
--bucket $lab_bucket \
--body object01.txt \
--key new_object01.txt
 Expected output:


******************************
**** This is OUTPUT ONLY. ****
******************************

An error occurred (AccessDenied) when calling the PutObject operation: Access Denied
 Command: To test if you can get an object from Public-Instance, run the following command:
Public-Instance$


aws --endpoint-url https://s3.$lab_region.amazonaws.com s3api get-object \
--bucket $lab_bucket \
--key object01.txt \
new_object01.txt
 Expected output:


******************************
**** This is OUTPUT ONLY. ****
******************************

An error occurred (AccessDenied) when calling the GetObject operation: Access Denied
All testing from the public instance should be denied because it is not originating from the VPC endpoint in the private subnet.

Testing from Private-Instance

 Command: To test if you can list the bucket objects from Private-Instance, run the following command:
Private-Instance$


aws --endpoint-url https://s3.$lab_region.amazonaws.com s3api list-objects --bucket $lab_bucket
 Expected output:


******************************
**** This is OUTPUT ONLY. ****
******************************

{
    "Contents": [
        {
            "LastModified": "2022-09-12T02:20:00.000Z",
            "ETag": "\"f9a29703c427f46f94fd76e5baf2222f\"",
            "StorageClass": "STANDARD",
            "Key": "object01.txt",
            "Size": 40
        }
    ]
}
 Command: To create an object on Private-Instance, run the following command:
Private-Instance$


echo 'This is the 2nd test object for the lab' > object02.txt
 Expected output:

None, unless there is an error.

 Command: To test if you can put an object to the bucket from Private-Instance, run the following command:
Private-Instance$


aws --endpoint-url https://s3.$lab_region.amazonaws.com s3api put-object \
--bucket $lab_bucket \
--body object02.txt \
--key object02.txt
 Expected output:


******************************
**** This is OUTPUT ONLY. ****
******************************

{
    "SSEKMSKeyId": "arn:aws:kms:us-east-1:111122223333:key/1c446a23-24aa-4388-8f0f-0ff2f5b37c86",
    "ETag": "\"4b3eb9639d00b7c6e4f6ab26d4af785f\"",
    "ServerSideEncryption": "aws:kms"
}
 Command: To test if you can get an object from Private-Instance, run the following command:
Private-Instance$


aws --endpoint-url https://s3.$lab_region.amazonaws.com s3api get-object \
--bucket $lab_bucket \
--key object02.txt \
new_object02.txt
 Expected output:


******************************
**** This is OUTPUT ONLY. ****
******************************

{
    "AcceptRanges": "bytes",
    "ContentType": "binary/octet-stream",
    "LastModified": "Mon, 12 Sep 2022 02:55:26 GMT",
    "ContentLength": 40,
    "ETag": "\"4b3eb9639d00b7c6e4f6ab26d4af785f\"",
    "ServerSideEncryption": "aws:kms",
    "SSEKMSKeyId": "arn:aws:kms:us-east-1:111122223333:key/1c446a23-24aa-4388-8f0f-0ff2f5b37c86",
    "Metadata": {}
}
All testing from the private instance should be successful because it is originating from the VPC endpoint.

Close the Public-Instance Session Manager window because you do not need it after this task.
 Congratulations! You have applied the second rule of your compliance requirements on your bucket by restricting access to the bucket from the private subnet gateway endpoint and validated it.

Task 4: Restricting object uploads to your preferred encryption option and AWS KMS key
In this task, you perform the following:

Test uploading objects to the bucket using different encryption options and keys.
Add a third statement to your bucket policy to enforce the AWS KMS encryption option and your preferred AWS KMS key for all uploads to the bucket.
Validate that the bucket policy is correct.
The lab environment has two AWS KMS keys created. The aliases of these two keys are as follows:

kms-green-key
kms-red-key
The IDs of both keys are provided in the Resources pane to the left of these instructions.

In the Amazon S3 console, under Buckets, locate where the buckets are listed and choose the mybucketlab-<RANDOM_NUMBER> link for your bucket.

Choose the Properties tab and scroll down to check the Default Encryption settings on the bucket. Notice that the bucket is set to use SSE-KMS using a specific AWS KMS key, which matches the ID of kms-green-key.

When you uploaded the previous objects, you did not specify any encryption option or key to be used.

In the Amazon S3 console, under your bucket, choose the Objects tab, choose the object link of any object that you uploaded in the previous tasks, and then scroll down in the object properties. Notice that this object used kms-green-key as the main key for envelop encryption because it is set as the default key for the bucket. This is the only key that you approve in your bucket as part of the compliance.
 Note:

For more information about Amazon S3 encryption, see Protecting Data Using Server-Side Encryption.
All the remaining testing will now occur from the private instance because it is the only instance that you access the bucket with.
 Command: To create another object on Private-Instance, run the following command:
Private-Instance$


echo 'This is a red key object' > red_object.txt
 Expected output:

None, unless there is an error.

 Command: To upload the new object using kms-red-key, run the following command:
Private-Instance$


aws --endpoint-url https://s3.$lab_region.amazonaws.com s3api put-object \
--bucket $lab_bucket \
--body red_object.txt \
--key red_object.txt \
--server-side-encryption aws:kms \
--ssekms-key-id $kms_red_key_id
 Expected output:


******************************
**** This is OUTPUT ONLY. ****
******************************

{
    "SSEKMSKeyId": "arn:aws:kms:us-east-1:111122223333:key/30892466-ed5b-4f32-9a0d-fd8e344421fd",
    "ETag": "\"c868e21b537a10f79f4670013677890e\"",
    "ServerSideEncryption": "aws:kms"
}
The upload should be successful.

On the Objects tab under your bucket, choose red_object.txt, scroll down its properties, and notice that it is using kms-red-key.

 Command: To create another object on Private-Instance, run the following command:

Private-Instance$


echo 'This is an sse-s3 object' > sses3_object.txt
 Expected output:

None, unless there is an error.

 Command: To upload the new object using SSE-S3, which does not even use your AWS KMS keys, run the following command:
Private-Instance$


aws --endpoint-url https://s3.$lab_region.amazonaws.com s3api put-object \
--bucket $lab_bucket \
--body sses3_object.txt \
--key sses3_object.txt \
--server-side-encryption AES256
 Expected output:


******************************
**** This is OUTPUT ONLY. ****
******************************

{
    "ETag": "\"11eba73b35d5f3120128614016e52d22\"",
    "ServerSideEncryption": "AES256"
}
The upload should be successful.

On the Objects tab, under your bucket, choose sses3_object.txt and scroll down its properties. Notice that it uses SSE-S3.
What you can conclude from these tests is that setting the bucket default encryption will only be applied if you don’t specify any encryption or key options during uploads. However, you can override the default settings, if you choose to, during uploads. As a bucket owner, you can see that there might be a compliance issue, and you want to ensure that all uploads use AWS KMS and your preferred key, which is kms-green-key in this scenario.

Do it yourself

Modify your bucket policy by adding a new statement that denies any object uploads that do not use kms-green-key.
 Hint: For hints on how to complete this task, see Protecting Data Using Server-Side Encryption with AWS Key Management Service (SSE-KMS).

 Note: For the purpose of this lab scenario, when you use this reference, consider the following:

You do not need the bucket policy statement with the Null condition because the bucket is already configured with default encryption. However, if you decide to use it, it still meets the requirements.
Because you want to enforce using a specific AWS KMS key, consider using the following IAM condition: s3:x-amz-server-side-encryption-aws-kms-key-id to specify the key ID instead of the encryption method.
With this condition, you need to use the key ARN and not the key ID in the policy.
You only need the s3:PutObject action in this statement.
If you get stuck

For the full solution, in the Solutions section, see Task 4 solution .

Now, verify that the bucket policy that you configured is correct.

Command: To test if you can upload an object using kms-red-key, run the following command:
Private-Instance$


aws --endpoint-url https://s3.$lab_region.amazonaws.com s3api put-object \
--bucket $lab_bucket \
--body red_object.txt \
--key red_object.txt \
--server-side-encryption aws:kms \
--ssekms-key-id $kms_red_key_id
 Expected output:


******************************
**** This is OUTPUT ONLY. ****
******************************

An error occurred (AccessDenied) when calling the PutObject operation: Access Denied
 Command: To test if you can upload an object using SSE-S3, run the following command:
Private-Instance$


aws --endpoint-url https://s3.$lab_region.amazonaws.com s3api put-object \
--bucket $lab_bucket \
--body sses3_object.txt \
--key sses3_object.txt \
--server-side-encryption AES256
 Expected output:


******************************
**** This is OUTPUT ONLY. ****
******************************

An error occurred (AccessDenied) when calling the PutObject operation: Access Denied
If your bucket policy is correct, both of these tests that you just performed should result in denials because they do not use the required encryption option and key.

 Command: To test if you can upload an object using kms-green-key, run the following command:
Private-Instance$


aws --endpoint-url https://s3.$lab_region.amazonaws.com s3api put-object \
--bucket $lab_bucket \
--body object02.txt \
--key task4_object.txt \
--server-side-encryption aws:kms \
--ssekms-key-id $kms_green_key_id
 Expected output:


******************************
**** This is OUTPUT ONLY. ****
******************************

{
    "SSEKMSKeyId": "arn:aws:kms:us-east-1:111122223333:key/1c446a23-24aa-4388-8f0f-0ff2f5b37c86",
    "ETag": "\"e36932ab26479f7f056817b550637930\"",
    "ServerSideEncryption": "aws:kms"
}
This test should be successful, and you can verify that it is by using the correct key on the object’s properties.

 Congratulations! You have applied the third rule of your compliance requirements on your bucket to enforce uploading objects using only a specific encryption option and encryption key, and you validated it.

Summary
 Congratulations! You have now successfully done the following:

Configured your bucket policy to only accept HTTPS connections.
Configured your bucket policy to only accept API calls that originate from a specific subnet through the VPC endpoint.
Configured your bucket policy to only accept uploads that use a specific encryption method and AWS KMS key.
Applied your rules to your bucket based on your compliance requirements.
The lab scenario might not exactly match your environment, but you should now have the skills required to enforce your rules on your buckets.

For more information, see Security Best Practices for Amazon S3.

End lab
Follow these steps to close the console and end your lab.

Return to the AWS Management Console.

At the upper-right corner of the page, choose AWSLabsUser, and then choose Sign out.

Choose End lab and then confirm that you want to end your lab.

Additional resources
For more information about how to use Amazon S3, see Amazon S3 documentation.
For more information about how to use Amazon VPC, see Amazon VPC documentation.
For more information about how to use AWS IAM, see IAM documentation.
For more information about how to use AWS KMS, see AWS KMS documentation.
For more information about AWS Training and Certification, see https://aws.amazon.com/training/.

Your feedback is welcome and appreciated.
If you would like to share any feedback, suggestions, or corrections, please provide the details in our AWS Training and Certification Contact Form.

Solutions

TASK 2 SOLUTION – ENFORCING HTTPS CONNECTIONS
In the Amazon S3 console, under Buckets, locate where the buckets are listed and choose the mybucketlab-<RANDOM_NUMBER> link for your bucket.

To add a new policy statement, choose the Permissions tab, scroll down to the Bucket Policy section, and choose Edit.

In the Policy pane, after replacing the resources with your bucket name, enter the following policy :

 Copy command: You might want to copy this policy to your preferred note editor, update the values, and then paste it back into the Policy pane. You can find your bucket name in the Resources pane to the left of these instructions.


{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "Allow SSL Requests Only",
        "Action": "s3:*",
        "Effect": "Deny",
        "Resource": [
          "arn:aws:s3:::REPLACE_WITH_YOUR_BUCKET_NAME",
          "arn:aws:s3:::REPLACE_WITH_YOUR_BUCKET_NAME/*"
        ],
        "Principal": "*",
        "Condition": {
            "Bool": {
              "aws:SecureTransport": "false"
            }
          }
      }
    ]
}
Scroll to the bottom and choose Save Changes..
Return to Task 2


TASK 3 SOLUTION – ENFORCING ACCESS TO THE BUCKET THROUGH THE VPC ENDPOINT
In the Amazon S3 console, under Buckets, locate where the buckets are listed and choose the mybucketlab-<RANDOM_NUMBER> link for your bucket.

To add a new statement to your policy, choose the Permissions tab, scroll down to the Bucket Policy section, and choose Edit.

In the Policy pane, replace the current policy with the following one after replacing the bucket name, Amazon EC2 role ARN, and the VPC endpoint ID from the Resources pane to the left of these instructions. Note that the first statement for enforcing HTTPS connections is not changed. A new statement is added for this task and the JSON syntax is adjusted.

 Copy command: You might want to copy this policy on your preferred note editor, update the values, and then paste it back into the Policy pane.


{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "AllowSSLRequestsOnly",
        "Action": "s3:*",
        "Effect": "Deny",
        "Resource": [
          "arn:aws:s3:::REPLACE_WITH_YOUR_BUCKET_NAME",
          "arn:aws:s3:::REPLACE_WITH_YOUR_BUCKET_NAME/*"
        ],
        "Principal": "*",
        "Condition": {
            "Bool": {
              "aws:SecureTransport": "false"
            }
          }
      },
      {    
        "Sid": "Restrict Access only from VPC Endpoint",
        "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:ListBucket"
            ],
        "Effect": "Deny",
        "Resource": [
          "arn:aws:s3:::REPLACE_WITH_YOUR_BUCKET_NAME",
          "arn:aws:s3:::REPLACE_WITH_YOUR_BUCKET_NAME/*"
        ],
        "Principal": {"AWS": "REPLACE_WITH_EC2_ROLE_ARN"},
        "Condition": {
            "StringNotEquals": {
              "aws:SourceVpce": "REPLACE_WITH_YOUR_VPC_ENDPOINT_ID"
            }
          }
      }
    ]
}
Scroll to the bottom and choose Save Changes..
Return to Task 3


TASK 4 SOLUTION - RESTRICTING OBJECT UPLOADS TO YOUR PREFERRED ENCRYPTION OPTION AND AWS KMS KEY
In the Amazon S3 console, under Buckets, locate where the buckets are listed and choose the mybucketlab-<RANDOM_NUMBER> link for your bucket.

To add a new statement to your policy, choose the Permissions tab, scroll down to the Bucket Policy section, and choose Edit.

In the Policy pane, replace the current policy with the following one after replacing the bucket name, VPC endpoint ID, Amazon EC2 role ARN, and kms-green-key ARN values from the Resources pane to the left of these instructions. Note that the first two statements are not changed. A new statement is added for this task and the JSON syntax is adjusted.

 Copy command: You might want to copy this policy on your preferred note editor, update the values, and then paste it back into the Policy pane.


{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "Allow SSL Requests Only",
        "Action": "s3:*",
        "Effect": "Deny",
        "Resource": [
          "arn:aws:s3:::REPLACE_WITH_YOUR_BUCKET_NAME",
          "arn:aws:s3:::REPLACE_WITH_YOUR_BUCKET_NAME/*"
        ],
        "Principal": "*",
        "Condition": {
            "Bool": {
              "aws:SecureTransport": "false"
            }
          }
      },
      {    
        "Sid": "Restrict Access only from VPC Endpoint",
        "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:ListBucket"
            ],
        "Effect": "Deny",
        "Resource": [
          "arn:aws:s3:::REPLACE_WITH_YOUR_BUCKET_NAME",
          "arn:aws:s3:::REPLACE_WITH_YOUR_BUCKET_NAME/*"
        ],
        "Principal": {
                "AWS": "REPLACE_WITH_EC2_ROLE_ARN"
            },
        "Condition": {
            "StringNotEquals": {
              "aws:SourceVpce": "REPLACE_WITH_YOUR_VPC_ENDPOINT_ID"
            }
          }
      },
      {
                "Sid": "Deny Incorrect KMS Keys",
                "Effect": "Deny",
                "Principal": "*",
                "Action": "s3:PutObject",
                "Resource": "arn:aws:s3:::REPLACE_WITH_YOUR_BUCKET_NAME/*",
                "Condition": {
                    "StringNotEquals": {
                          "s3:x-amz-server-side-encryption-aws-kms-key-id": "REPLACE_WITH_YOUR_GREEN_KEY_ARN"
                             }
                   }
           }
    ]
}