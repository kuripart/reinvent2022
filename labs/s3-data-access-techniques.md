Exploring Amazon S3 Data Access Techniques

Overview
You work for a transportation company exploring the potential new market of self-driving cars. Your team is testing prototype self-driving cars that drive throughout the day collecting data. Part of this data includes information on roadblocks, potholes, traffic conditions, and so on. At night, the cars return to the garage and upload their data to Amazon Simple Storage Service (Amazon S3) for further processing and analysis. Your management team requested an application that they can use to interact with specific reports generated from that data.

If the initial pilot is successful, your company will start offering this self-driving car technology to potential customers at a global scale. As with any new technology, people still have many reservations about whether your offering is mature enough for the market. To address any doubts, your company plans to offer prospective customers supporting data to reassure them that your self-driving cars are reliable and ready for prime time. You are responsible for ensuring optimal performance of all data transfer activities related to this project.

This lab follows the Amazon S3 Performance Optimization course, which covers features and techniques that you can use to obtain optimal performance when using Amazon S3.

TOPICS COVERED
By the end of this lab, you will be able to:

Use Amazon S3 Select to retrieve specific object data from CSV- and GZIP-formatted files.
Describe the benefits of using parallelization.
Configure an Amazon CloudFront distribution with an Amazon S3 bucket as the origin.
TECHNICAL KNOWLEDGE PREREQUISITES
To successfully complete this lab, you should have a general familiarity with AWS as covered in the AWS Cloud Practitioner Essentials course.

Task 1: Environment overview
In this task, you review the lab environment to gain a better understanding of what you will be working with throughout the course of the lab.

The following diagram shows the basic architecture of the lab environment:

The architecture diagram of the lab environment, which shows an Amazon VPC with a single public subnet, one EC2 instance, two S3 buckets named daily-uploads and cloudfront-origin, and an Amazon CloudFront download distribution.

The following list details the major resources in the diagram:

Amazon Elastic Compute Cloud (Amazon EC2) T3 instance. The instance resides in a public subnet, but network access is restricted to only the traffic required to complete this lab.
daily-uploads S3 bucket, which is prepopulated with CSV and Gzip formatted files.
cloudfront-origin S3 bucket, which is empty. You upload a sample website to the bucket in Task 4. It serves as the origin source for the CloudFront download distribution.
You create the Amazon CloudFront download distribution in Task 4.
First, examine the configuration of the S3 buckets.

If you have not already done so, follow the steps in the Start Lab section to log into the AWS Management Console.

At the top of the page, in the unified search bar, search for and choose 

S3.

On the Amazon S3 Buckets page, choose the link for the bucket name that starts with daily-uploads.

On the Objects tab, notice there are two objects in the bucket: TrafficEvents.csv and TrafficEvents.csv.gz.

Choose the Permissions tab.

On the Permissions tab, review the security settings for the bucket. Notice that Block all public access is enabled and there are no bucket policies. Since all public access is blocked, and the object writer remains the object owner, only your account has access to the bucket and objects within it. For the purposes of this lab, you access the objects using the AWS Management Console, an Amazon EC2 instance, and Amazon CloudFront.

Choose the Objects tab.

Select the checkbox next to the TrafficEvents.csv object.

Choose Download to download a copy of the CSV file to your computer.

Open the CSV file you downloaded and examine its contents. Data in the file is classified by zip code and event, similar to the following table:

zip code	event
98101	accident
98101	traffic jam
98101	roadblock
98101	accident
10023	traffic jam
10023	traffic jam
Now that you have a better understanding of the lab environment and files you will be working with, the real fun can begin!

Task 2: Use S3 Select to retrieve data from CSV and GZIP files
Your application retrieves the data in Amazon S3 that the self-driving cars collect each day and then sort the traffic incidents by zip code. The application currently downloads the entire CSV file. To improve application performance, you would like to identify a mechanism to retrieve specific data, rather than the entire file.

Amazon S3 Select enables you to use simple Structured Query Language (SQL) statements to filter S3 object contents. Filtering for only the data you need, rather than the entire object, reduces latency and costs for retrieving the data. For more information, refer to Filtering and retrieving data using Amazon S3 Select in the Additional resources section.

In this task, you use a Python script and Amazon S3 Select to retrieve traffic incidents with a specific zip code from CSV and Gzip formatted files.

TASK 2.1: CONNECT TO THE EC2 INSTANCE
At the top of the page, in the unified search bar, search for and choose 

EC2.

In the navigation pane at the left of the page, choose Instances.

Select the checkbox next to Lab Instance and then, at the top-right of the page, choose Connect

On the Connect to instance page, choose the Session Manger tab, and then choose Connect

 A new browser tab opens with a console connection to the instance. A set of commands are run automatically when you connect to the instance that change to the user’s home directory and display the path of the working directory, similar to this:


cd $HOME; pwd
sh-4.2$ cd $HOME; pwd
/home/ec2-user
sh-4.2$
 On a Windows-based computer, use Ctrl + Shift + V to paste text into a Session Manager console window.

TASK 2.2: CREATE THE PYTHON SCRIPT
Next, you create a Python script that uses the AWS SDK for Python (Boto3) to filter and retrieve data from an object in an S3 bucket.

 In the Session Manager console, run the following command to create a Python script named select-data.py, which queries data in the S3 bucket:

cat << EOF > select-data.py
import boto3
s3 = boto3.client('s3')

zip = input("Enter a zip code: ")
bucketName = input("Enter the S3 bucket name: ")

resp = s3.select_object_content(
    Bucket=bucketName,
    Key='TrafficEvents.csv',
    ExpressionType='SQL',
    Expression=(f"SELECT * from s3object s where s.\"zip code\" = '{zip}'"),
    InputSerialization = {'CSV': {"FileHeaderInfo": 'Use'}, 'CompressionType':'NONE'},
    OutputSerialization = {'CSV': {}},
)
for event in resp['Payload']:
    if 'Records' in event:
        records = event['Records']['Payload'].decode('utf-8')
        print(records)
    elif 'Stats' in event:
        statsDetails = event['Stats']['Details']
        print("Stats details bytesScanned: ")
        print(statsDetails['BytesScanned'])
        print("Stats details bytesProcessed: ")
        print(statsDetails['BytesProcessed'])
EOF
The script you just created prompts you for a zip code and S3 bucket name, scans a CSV file in the S3 bucket for entries containing that zip code, and then outputs the results. The following list describes some of the key elements of the script:

zip = input () prompts you for a zip code and stores the value you enter in a variable named zip
bucketName = input () prompts you for the name of the S3 bucket the object to scan is stored in and stores the value you enter in a variable named bucketName
Key specifies the path to the object in the S3 bucket. In this lab, the object you retrieve data from is stored at the root of the bucket. If your object is in a folder your Key value would look similar to this: 

folder1/folder2/TrafficEvents.csv
Expression is the SQL query that specifies the data to retrieve. In this example, you are selecting all entries with a zip code that matches the one entered at the time the script is run.
InputSerialization specifies the file format and compression type of the object to query. For more information about supported file and compression types, refer to Filtering and retrieving data using Amazon S3 Select in the Additional resources section.
 Run the following command to run the Python script:

python3 select-data.py
When prompted:
For Enter a zip code, enter 

98101
For Enter the S3 bucket name, enter the value of DailyUploadsBucket listed to the left of these instructions.
 The output should list a number of traffic events collected from the self-driving car operating in the 98101 zip code, similar to this:


98101,accident
98101,traffic jam
98101,roadblock
98101,accident
98101,accident
98101,accident
98101,pothole
98101,traffic jam
98101,pothole
 The objects in the bucket have entries for the following zip codes: 98101, 10023, 92105, 77015, 02124. Try experimenting with different zip codes to view the results.

Challenge yourself! Now that you have observed how you can retrieve a subset of information from a CSV file in an S3 bucket, how might you modify the Python script to retrieve data from the Gzip file in the same bucket?

Refer to the Answer key section for the answer!

 Congratulations! You have successfully used the AWS SDK for Python and Amazon S3 select to retrieve a specific set of data from an object in an S3 bucket!

Task 3: Explore parallelization
You’ve now used Amazon S3 Select to reduce the amount of data retrieved from S3 for each data query. However, you’re concerned that the self-driving cars might eventually collect too much information to upload in an efficient manner and limit your ability to get results to your potential customers quickly. You’d like to explore the effects of parallelization to further optimize file upload performance.

In this task, you experiment with various AWS Command Line Interface (CLI) settings for Amazon S3 that impact upload performance.

 In the Session Manager console, run the following commands to configure the Amazon S3 upload settings in the AWS CLI on this instance:
Specify the maximum number of concurrent Amazon S3 transfer requests that can run at the same time:


aws configure set default.s3.max_concurrent_requests 1
Specify the size threshold that the AWS CLI uses to trigger Amazon S3 multipart transfers of individual files:


aws configure set default.s3.multipart_threshold 64MB
Specify the chunk size that the AWS CLI uses for Amazon S3 multipart transfers of individual files:


aws configure set default.s3.multipart_chunksize 16MB
 For more information, refer to SDK and tool settings for Amazon S3 APIs in the Additional resources section.

 Run the following command to display the contents of the AWS CLI configuration file and verify the S3 settings applied successfully:

cat ~/.aws/config
 The output should look similar to this:


[default]
s3 =
    max_concurrent_requests = 1
    multipart_threshold = 64MB
    multipart_chunksize = 16MB
 Run the following command to create a 3GB file to use for testing upload performance:

dd if=/dev/urandom of=3GB.file bs=1 count=0 seek=3G
 The output should look similar to this:


0+0 records in
0+0 records out
0 bytes (0 B) copied, 0.000127823 s, 0.0 kB/s
 dd is a Linux utility that is primarily used to convert or copy files. However, it can also read from special device files, such as /dev/urandom. /dev/urandom is a special system file that can be used as a source of random data. In this example, you use dd to create a 3 GB file that is full of random data.

 Run the following command to store the name of the S3 bucket you are working with in a system variable, which eliminates the need to modify future commands in this guide that require the bucket name:
Replace BUCKET_NAME with the value of DailyUploadsBucket listed to the left of these instructions.

bucketname=BUCKET_NAME
 Run the following command to upload the test file to the S3 bucket and display the time it takes to complete the upload:

time aws s3 cp 3GB.file s3://$bucketname/upload1.test
 The upload should complete in approximately 60 to 90 seconds and the output of the command should look like this:


upload: ./3GB.file to s3://daily-uploads-33975528/upload1.test

real    1m12.396s
user    0m14.864s
sys     0m7.733s
Next, modify the AWS CLI settings to increase the number of concurrent requests, upload the test file again, and note the differences in upload time.

 Run the following commands to set the number of concurrent requests to three and upload the test file:

aws configure set default.s3.max_concurrent_requests 3

time aws s3 cp 3GB.file s3://$bucketname/upload2.test
 The upload should complete in approximately 30 to 40 seconds and the output of the command should look like this:


upload: ./3GB.file to s3://daily-uploads-33975528/upload2.test

real    0m33.107s
user    0m17.480s
sys     0m10.119s
Now try ten concurrent requests.

 Run the following commands to set the number of concurrent requests to ten and upload the test file:

aws configure set default.s3.max_concurrent_requests 10

time aws s3 cp 3GB.file s3://$bucketname/upload3.test
 The upload should complete in approximately 25 to 30 seconds and the output of the command should look like this:


upload: ./3GB.file to s3://daily-uploads-33975528/upload3.test

real    0m29.053s
user    0m24.201s
sys     0m20.108s
 Notice that the time between three (33.107s) and ten (29.053s) concurrent requests is not very significant. The number of concurrent requests is not the only factor in upload or download rates. The EC2 instance you are using for this lab is a t3.micro instance, which has a network speed of up to 5 Gbps. When the same exercise is performed on a c5.large instance, which has a network speed of up to 10 Gbps, the difference is more noticeable, with results like this:

3 concurrent requests	10 concurrent requests
real 0m28.646s
user 0m14.170s
sys 0m7.030s	real 0m18.048s
user 0m17.337s
sys 0m13.863s
 For more information, refer to EC2 Instance Types in the Additional resources section.

 Congratulations! You have successfully modified the Amazon S3 transfer settings for the AWS CLI and observed how changing the concurrent requests setting can affect upload performance!

Task 4: Use Amazon CloudFront to securely cache frequently accessed content
Your company plans to offer a webpage for their globally distributed customer base. The webpage contains static content of the self-driving cars, such as pictures, specifications, and videos. Your team requested that you ensure the content is delivered securely and reliably.

In this task, you create a CloudFront download distribution with an S3 bucket as the origin. You then configure Origin Access Identity (OAI) to restrict access to the website.

TASK 4.1: UPLOAD WEBSITE FILES TO THE S3 BUCKET
In this task, you upload the files for the static website to the S3 bucket. You then validate the current permissions settings for the bucket and its contents.

 In the Session Manager console, run the following command to copy the files for a sample website to an S3 bucket:
Replace BUCKET_NAME with the value of CloudFrontOriginBucket listed to the left of these instructions.

aws s3 cp --include "*" --recursive /temp/website/ s3://BUCKET_NAME
Return to your AWS Management Console browser tab.

At the top of the page, in the unified search bar, search for and choose 

S3.

Choose the link for the bucket name that starts with cloudfront-origin.

On the Objects tab, verify the files you uploaded are listed. You should see the following files:

 index.html
 images
 iot.png
 car.png
 logo.png
If you browsed to the contents of the images folder, use your browser’s back button or the breadcrumbs at the top of the page to return to the main Objects page.

Choose the Permissions tab.

On the Permissions tab, review the security settings for the bucket. You should notice that Block all public access is enabled, there are no bucket policies, and only your account has access to the bucket and objects within it.

TASK 4.2: CREATE A CLOUDFRONT DOWNLOAD DISTRIBUTION
Next, create a CloudFront distribution to securely deliver the website contents that you uploaded to the cloudfront-origin bucket.

At the top of the page, in the unified search bar, search for and choose 

CloudFront.

At the left of the page, on the CloudFront navigation pane, choose Distributions.

Choose Create distribution

For Origin domain, copy and paste the value of OriginDomainName listed to the left of these instructions. OriginDomainName shows the regional domain name of the cloudfront-origin bucket, rather than the global domain name.

For Origin access, select Legacy access identities.

For S3 bucket access, select Yes use OAI.

Choose Create new OAI.

Choose Create.

For Bucket policy, select Yes, update the bucket policy.

In the Default cache behavior section for Viewer, select Redirect HTTP to HTTPS.

Choose Create distribution

At the left of the page, on the CloudFront navigation pane, choose Distributions.

 You should see your new distribution listed with a status of  Deploying.

Wait until the distribution finishes creating, which can take up to five minutes.

Choose the link for your distribution.

Make note of the Distribution Domain name value, which should look similar to this: dpqb4mgwuql35.cloudfront.net. You use it in an upcoming step to create the website URL.

At the left of the page, on the CloudFront navigation pane, under Security, choose Origin access.

Choose Identities (Legacy).

Make a note of the Origin access identities ID, which should look similar to this: E1FWPUN776XWQ2. You use it in an upcoming step to verify an S3 bucket policy.

TASK 4.3: EXAMINE CHANGES TO THE S3 BUCKET PERMISSIONS AND ACCESS THE WEBSITE
Now that you have created the CloudFront download distribution, examine the bucket policy that CloudFront created for you.

At the top of the page, in the unified search bar, search for and choose 

S3.

Choose the link for the bucket name that starts with cloudfront-origin.

Choose the Permissions tab.

On the Permissions page, review the security settings for the bucket. You should notice that Block all public access is still enabled. However, a new bucket policy has been added that allows the CloudFront Origin Access Identity you created previously to access the contents of the bucket. It should look similar to this:


{
    "Version": "2008-10-17",
    "Id": "PolicyForCloudFrontPrivateContent",
    "Statement": [
        {
            "Sid": "1",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity E1FWPUN776XWQ2"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::cloudfront-origin-43851759/*"
        }
    ]
}
Verify the Origin Access Identity ID that you noted earlier matches the one in the policy. You can locate it at the end of the line that begins with “AWS”:

Also notice that the policy grants read access, via the s3:GetObject action, to the entire cloudfront-origin bucket as shown in the “Resource”: parameter. If you were to instead configure CloudFront to be limited to objects within a folder in the bucket instead, that folder path would be included in the resource parameter.

TASK 4.4: ACCESS THE WEBSITE
Now that you have configured CloudFront to access the website files in the bucket, you can test that it’s working. First, try to access any of the files directly from the S3 bucket.

Choose the Objects tab to return to the list of objects.

Choose the link for the index.html object.

On the Object overview page, copy the value of Object URL. It should look similar to this:


https://cloudfront-origin-43851759.s3-us-west-2.amazonaws.com/index.html

Open a new browser tab and navigate to the URL you copied.
You should receive an Access Denied error message, similar to this:


<Error>
    <Code>AccessDenied</Code>
    <Message>Access Denied</Message>
    <RequestId>M80R9TWTXPTFZEZJ</RequestId>
    <HostId>r37c9M/MPJivBLz0ZBTgyCiHmzifbrWr0UlMa/CgqRR5ITrjih7vBHIJicXqsqNxlOmvv/2lDcY=</HostId>
</Error>
In the address bar, replace the domain portion of the URL with the CloudFront domain name you made a note of previously. The URL should now look similar to this:

https://dpqb4mgwuql35.cloudfront.net/index.html

Browse to the updated URL. The sample webpage should now load successfully.
A screenshot of the sample webpage.

 The CloudFront URL directs your request for the website HTML file through the CloudFront service. When you created the CloudFront distribution, you created an Origin Access Identity (OAI). The OAI is a special CloudFront user that is associated with the distribution. You also created an S3 bucket policy with the distribution that grants read access for the OAI to the objects in the bucket. Since the OAI associated with the distribution has access to the bucket, the request from CloudFront is allowed. However, when you attempt to access the same file using the direct S3 URL, the request is blocked because you are making the request from an unknown client.

 Congratulations! You have successfully created a CloudFront distribution to securely serve static website content from an S3 bucket!

Conclusion
 Congratulations! You have successfully:

Used Amazon S3 Select to retrieve specific object data from CSV- and GZIP-formatted files.
Explored the benefits of using parallelization.
Configured an Amazon CloudFront distribution with an Amazon S3 bucket as the origin.
End lab
Follow these steps to close the console and end your lab.

Return to the AWS Management Console.

At the upper-right corner of the page, choose AWSLabsUser, and then choose Sign out.

Choose End lab and then confirm that you want to end your lab.

Additional resources
Filtering and retrieving data using Amazon S3 Select
Maximizing storage performance
AWS News Blog: S3 Select and Glacier Select – Retrieving Subsets of Objects
AWS News Blog: Querying data without servers or databases using Amazon S3 Select
SQL reference for Amazon S3 Select and S3 Glacier Select
SDK and tool settings for Amazon S3 APIs
EC2 Instance Types
For more information about AWS Training and Certification, see https://aws.amazon.com/training/.

Your feedback is welcome and appreciated.
If you would like to share any feedback, suggestions, or corrections, please provide the details in our AWS Training and Certification Contact Form.

Answer key
TASK 2.2
To modify the Python script to retrieve data from a Gzip file instead of a CSV, adjust the following lines:

For Key, change the path and file name to point to the Gzip file.
For InputSerialization, change CompressionType to GZIP.

cat << EOF > gzip-data.py
import boto3
import boto3
s3 = boto3.client('s3')

zip = input("Enter a zip code: ")
bucketName = input("Enter the S3 bucket name: ")

resp = s3.select_object_content(
    Bucket=bucketName,
    Key='TrafficEvents.csv.gz',
    ExpressionType='SQL',
    Expression=(f"SELECT * from s3object s where s.\"zip code\" = '{zip}'"),
    InputSerialization = {'CSV': {"FileHeaderInfo": 'Use'}, 'CompressionType':'GZIP'},
    OutputSerialization = {'CSV': {}},
)
for event in resp['Payload']:
    if 'Records' in event:
        records = event['Records']['Payload'].decode('utf-8')
        print(records)
    elif 'Stats' in event:
        statsDetails = event['Stats']['Details']
        print("Stats details bytesScanned: ")
        print(statsDetails['BytesScanned'])
        print("Stats details bytesProcessed: ")
        print(statsDetails['BytesProcessed'])
EOF