How to Speed Up Your AWS Lambda Functions

Scenario
As a DevOps engineer at AnyCompany, Inc., you have been tasked with the responsibility of improving the performance of the company’s products API. The product data is stored in an Amazon DynamoDB table. Customers interact with this data through Amazon API Gateway endpoints that map requests to an AWS Lambda function. This application handles the following actions:

An HTTP Post method that creates new products
An HTTP Get method that retrieves a list of products
An HTTP Get method that retrieves a product by its product ID
An HTTP Delete method that deletes a product
Customers tell you that they want under 100 ms response times on all requests, but they have noticed that, on average, requests take longer. Occasionally, the customers have noticed response times of 1 second or more. These issues are more prevalent when the application is under load (about 200 requests per second).

You have been tasked with optimizing the products API so that average response times are as fast as possible and to solve responses that are taking 1 second or more. Using AWS Cloud9 as your development and testing environment, you will optimize your Lambda functions to meet customers’ expectations. You will use an open-source load testing tool called Locust to generate a load against your application.

Lab overview
It is time to dive deep into Lambda. You, as a DevOps engineer, need to improve Lambda response times for your serverless application. In this lab, you are going to finally understand concurrency, function memory size, cold starts, and how to achieve the best results using Lambda functions. You explore the lifecycle of a Lambda function and learn the ways in which to optimize your function for performance.

Objectives
By the end of this lab, you will be able to do the following:

Deploy a Lambda function using AWS Serverless Application Model (AWS SAM).
Observe the performance characteristics of the Lambda function to determine possible performance enhancements.
Adjust the memory size limit of a Lambda function to optimize performance.
Apply your knowledge of the Lambda function lifecycle to determine steps to optimize the function.
Configure provisioned concurrency and reserved concurrency on a Lambda function.
Use provisioned and reserved concurrency to optimize Lambda function performance.

Task 1: Set up your environment
In this task, you set up your AWS Cloud9 development environment so that you can build, deploy, and stress test the products API application. You modify the security group for your AWS Cloud9 instance to allow traffic to the Locust web interface on port 8089, which is the default port for Locust. You modify application configuration files to match your environment. Finally, you build and deploy your AWS SAM application.

TASK 1.1: CONFIGURE NETWORK SETTINGS FOR YOUR AWS CLOUD9 INSTANCE
In this task, you modify the security group for your AWS Cloud9 instance to allow traffic on port 8089.

In the search box in the upper left corner of the AWS Management Console, search for and choose EC2.

In the left pane under Network & Security, choose Security Groups.

Choose the security group that contains cloud9 in the Name field.

Under the Inbound rules tab, choose Edit inbound rules .

Choose Add rule .

In the new rule entry that is added, enter the following values:

Port range: 

8089

Source: 

Anywhere-IPv4

Choose Save rules .


TASK 1.2: OPEN YOUR AWS CLOUD9 INSTANCE
In this task, you connect to the AWS Cloud9 instance.

Open the Cloud9 environment by copying and pasting the URL value from the instructions to your left for the heading named, Cloud9Environment into a new browser tab.
Within a few seconds, the AWS Cloud9 environment launches. Notice the Linux-style terminal window in the bottom pane.

Open a new terminal window by choosing Window then choose New Terminal from the top of the AWS Cloud9 IDE.
 Note: If the browser is running in an incognito session, a pop-up window with an error message will be displayed when the AWS Cloud9 instance opens. Choose the OK button to continue. We recommend using the browser in a non-incognito mode.

TASK 1.3: DOWNLOAD THE SOURCE CODE FOR THE PRODUCTS API APPLICATION
Your team has built a simple web API that tracks products. The application consists of a Lambda function written in Python that stores product information in a DynamoDB table. The application is hosted behind an API Gateway. The application has endpoints for creating, deleting, and retrieving product information. In this task, you download the source code.

 Command: To download your source code, run the following commands in a terminal window.

mkdir app
cd app
wget https://us-west-2-aws-training.s3.amazonaws.com/courses/SPL-DD-300-SVOPLF/v1.0.1.prod-fc03a7ef/scripts/app-code-local.zip
These commands create an app directory and download the source code from an Amazon Simple Storage Service (Amazon S3) bucket.

 Expected output:


--2022-10-11 13:16:21--  https://us-west-2-aws-training.s3.amazonaws.com/courses/SPL-DD-300-SVOPLF/v1.0.1.dev-514a09d9/scripts/app-code-local.zip
Resolving us-west-2-aws-training.s3.amazonaws.com (us-west-2-aws-training.s3.amazonaws.com)... 52.92.145.241
Connecting to us-west-2-aws-training.s3.amazonaws.com (us-west-2-aws-training.s3.amazonaws.com)|52.92.145.241|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 3806 (3.7K) [application/zip]
Saving to: ‘app-code-local.zip’

100%[=========================================================================================================>] 3,806       --.-K/s   in 0s      

2022-10-11 13:16:21 (193 MB/s) - ‘app-code-local.zip’ saved [3806/3806]
TASK 1.4: UPDATE THE APPLICATION CONFIGURATION WITH VALUES FROM YOUR ENVIRONMENT
In this task, you initialize the AWS SAM application and update the samconfig.toml file with appropriate values.

AWS SAM is an open-source framework for building serverless applications. It provides shorthand syntax to express functions, APIs, databases, and event source mappings. With just a few lines per resource, you can define the application you want and model it using YAML. During deployment, AWS SAM transforms and expands the SAM syntax into AWS CloudFormation syntax so you can build serverless applications faster.

 Command: Run the following commands to initialize the AWS SAM application.

# Initialize the SAM application
sam init --location app-code-local.zip
# Install jq for reading json output
sudo yum -y install jq
# Update the SAM config file with environment specific variables
export BUCKET_NAME=$(aws s3api list-buckets --query "Buckets[?contains(Name, 'generatedbucket')].Name" --output text)
sed -Ei "s|<BUCKET_NAME>|${BUCKET_NAME}|g" samconfig.toml
export AWS_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
sed -Ei "s|<AWS_REGION>|${AWS_REGION}|g" samconfig.toml
export LAMBDA_ROLE_ARN=$(aws iam  list-roles --query "Roles[?contains(RoleName, 'LambdaDeployment')].Arn" --output text)
sed -Ei "s|<LAMBDA_ROLE_ARN>|${LAMBDA_ROLE_ARN}|g" samconfig.toml
# Install locust and faker
pip install locust==2.12.0 faker==15.0.0
# Make get_ip.sh executable
chmod 777 get_ip.sh
 Expected output: Output has been truncated.


******************************
**** This is OUTPUT ONLY. ****
******************************

        SAM CLI now collects telemetry to better understand customer needs.

        You can OPT OUT and disable telemetry collection by setting the
        environment variable SAM_CLI_TELEMETRY=0 in your shell.
        Thanks for your help!

        Learn More: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-telemetry.html


SAM CLI update available (1.65.0); (1.57.0 installed)
To download: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html
AWSLabsUser-rESsB5TBJBSaeePabTjJ3Q:~/environment/app $ # Install jq for reading json output
AWSLabsUser-rESsB5TBJBSaeePabTjJ3Q:~/environment/app $ sudo yum -y install jq
Loaded plugins: extras_suggestions, langpacks, priorities, update-motd
amzn2-core                                                                                                                                                                                                | 3.7 kB  00:00:00     
253 packages excluded due to repository priority protections
Resolving Dependencies



Your template contains a resource with logical ID "ServerlessRestApi", which is a reserved logical ID in AWS SAM. It could result in unexpected behaviors and is not recommended.
Building codeuri: /home/ec2-user/environment/app/product-api runtime: python3.7 metadata: {} architecture: x86_64 functions: ProductApiFunction
Running PythonPipBuilder:ResolveDependencies
Running PythonPipBuilder:CopySource

Build Succeeded

Built Artifacts  : .aws-sam/build
Built Template   : .aws-sam/build/template.yaml

Commands you can use next
=========================
[*] Validate SAM template: sam validate
[*] Invoke Function: sam local invoke
[*] Test Function in the Cloud: sam sync --stack-name {stack-name} --watch
[*] Deploy: sam deploy --guided
These commands initialize the AWS SAM application by unpacking the source code Zip file. The remaining commands install additional libraries needed to stress test your application. They also modify the AWS SAM application configuration file (samconfig.toml) with variables specific to your environment. Lastly, these commands make get_ip.sh script executable.

 Note: These commands might take about 30 seconds to run.

TASK 1.5: BUILD AND DEPLOY THE AWS SAM APPLICATION
In this task, you build and then deploy the AWS SAM application using CLI commands.

Run the following commands to build and deploy the application.

sam build
sam deploy --no-confirm-changeset
These commands build your AWS SAM application and deploy in your AWS environment. The deploy operation creates all the resources necessary for your application to run. This might take up to 2 minutes.

 Expected output:


******************************
**** This is OUTPUT ONLY. ****
******************************

-----------------------------------------------------------------------
CloudFormation outputs from deployed stack
-----------------------------------------------------------------------
Outputs                                                                                                                                        
-----------------------------------------------------------------------
Key                 ProductApiFunction                                                                                                         
Description         Product Api Lambda Function ARN                                                                                            
Value               arn:aws:lambda:us-west-2:986793401579:function:product-api-ProductApiFunction-i72OWA4ZvPdJ                                 

Key                 ProductApiUrl                                                                                                              
Description         API Gateway endpoint URL for Prod stage for Product Api function                                                           
Value               https://qfugdb05z9.execute-api.us-west-2.amazonaws.com                                                                     
-----------------------------------------------------------------------

Successfully created/updated stack - product-api in us-west-2
Copy the ProductApiUrl value from the output in the terminal and save it for later.
 Congratulations! You have prepared your environment and deployed the product API application.

Task 2: Run an initial Locust load test against your application and observe performance metrics
 Locust (https://locust.io) is an open-source load testing tool written using Python. With Locust, you can define load testing behavior with Python code and simulate large numbers of users accessing your application. In this task, use Locust to generate a load on your application and observe its behavior under stress.

Open a new terminal window by choosing Window then choose New Terminal from the top of the AWS Cloud9 IDE.
 Note: Using a new terminal window allows this program to keep running while you run additional commands in the original terminal window.

 Command: Start the Locust application by running the following commands in the new terminal window.

cd ~/environment/app
locust
 Expected output:


******************************
**** This is OUTPUT ONLY. ****
******************************

[2022-10-10 16:25:24,736] ip-10-0-1-137.us-west-2.compute.internal/INFO/locust.main: Starting web interface at http://0.0.0.0:8089 (accepting connections from all network interfaces)
[2022-10-10 16:25:24,750] ip-10-0-1-137.us-west-2.compute.internal/INFO/locust.main: Starting Locust 2.12.0
You are ready to access the Locust web interface.

 Command: In the original terminal window, run the following script to get the public IP address of your AWS Cloud9 instance.

~/environment/app/get_ip.sh
 Expected output: Your IP address will differ from the example shown below.


******************************
**** This is OUTPUT ONLY. ****
******************************

34.208.3.101
In a new browser window, open the following URL, replacing <ip-address> with the IP address you received in the previous step.

**********************************
**** This is an EXAMPLE ONLY. ****
**********************************

http://<ip-address>:8089
This is the Locust web application.

In the form that appears, enter the following values for your load test:
Number of users (peak concurrency): 

100

Spawn rate (users started/second): 

3

Host: enter the host name that you saved from the output of your AWS SAM template. It should look similar to 
https://yzshn7py28.execute-api.us-west-2.amazonaws.com.

Choose Start swarming and let the load test run until you see, at the top of the screen, STATUS RUNNING 100 users.

Choose  Stop to stop the load test.

Leave the Locust window open. You will return to it later to run another load test.

 Note: Review the statistics that Locust has collected. You will understand more about this screen in the next section.

TASK 2.1: UNDERSTAND THE RESULTS FROM LOCUST
Locust is set up to access your application through an API Gateway endpoint that initiates a Lambda function. It reports the statistics of transactions made from your AWS Cloud9 instance and includes all the time needed to make the requests and to retrieve the responses.

In Locust, you gather the pertinent information from the Statistics tab. The Statistics tab presents data related to each request and summarizes metrics from the load test. Important columns are as follows:

Type: The type of HTTP request
Name: The name of the request or the URL endpoint of the request
# Requests: The number of requests made to this endpoint
Fails: The number of requests that have failed resulting in a non-successful HTTP status code
Median (ms): The median response time in milliseconds
90%ile (ms): The 90th percentile response time in milliseconds
Average (ms): The average response time in milliseconds
Min (ms): The minimum response time in milliseconds
Max (ms): The maximum response time in milliseconds
Average size (bytes): The average size of the response in bytes
Current RPS: The current number of requests per second
Current failures/s: The current number of failures per second
The bottom row of the table presents an aggregate of all the request endpoints for the test.

From this screen, you are able to answer the following questions about your application’s performance:

In the Average (ms) column, what is the average response time?

In the Max (ms) column, what is the maximum response time?

Your customers are expecting average response times that are less than 100 ms, and maximum response times near 1 second are unacceptable.

TASK 2.2: UNDERSTAND THE METRICS IN THE LAMBDA CONSOLE UNDER THE MONITOR TAB
At the top of the AWS Management Console, in the search bar, search for and choose 

Lambda.

Choose the Lambda function that has product-api in the name.

In the middle of the screen following the Function overview section, select the Monitor tab.

The Monitor tab in the Lambda console provides performance metrics for your Lambda function. Unlike Locust, which covers the web transaction from the initial request to downloading the response, these statistics are only related to your Lambda function and its processing.

The Lambda Monitor tab tracks the following metrics:

Invocations: The number of times that the function was invoked
Duration: The average, minimum, and maximum amount of time your function code spends processing an event
Error count and success rate (%): The number of errors and the percentage of invocations that completed without error
Throttles: The number of times that an invocation failed due to concurrency limits
IteratorAge: For stream event sources, the age of the last item in the batch when Lambda received it and invoked the function
Async delivery failures: The number of errors that occurred when Lambda attempted to write to a destination or dead-letter queue
Concurrent executions: The number of function instances that are processing events
There are two things to pay attention to in the Lambda Monitor tab. First, note the Duration graph for the time that load was on the application. The average and maximum response times vary by quite a bit.

The Concurrent executions graph indicates that at the peak of the load on your application, approximately 40 Lambda functions were executing concurrently.

Is your application able to handle the number of users specified in your load test with an acceptable response time? Could your application perform faster?

 Congratulations! You have successfully ran an initial Locust load test against your application and observed performance metrics. You also reviewed and learned about the metrics in the Lambda console.

Task 3: Adjust the memory size of your Lambda function and redeploy
Optimizing your Lambda function starts with making sure that the right amount of memory and compute has been allocated. The default memory size limit is 128 MB. Determine if there is a performance boost to your function by adjusting the memory to 3008 MB.

Increasing the memory size limit of your Lambda function affects performance in two ways. It increases the maximum amount of memory available to your Lambda function. The amount of compute that your Lambda function has directly correlates with the memory size. The more memory that you allocate to your function, the more compute it has.

Note that adjusting the memory size limit also increases the cost per gigabit second for your function to run, but it might reduce the amount of time that your function needs to run to complete its task. In this task, you will adjust the memory and compute values for your Lambda function to improve performance.

Switch back to the browser tab opened to Cloud9.

On the left side of the AWS Cloud9 IDE, choose the dropdown arrow next to the app folder.

Choose and open the template.yaml file.

This file contains the AWS SAM template that defines your application’s AWS resources.

On line 25 of the template.yaml file, set the function memory size to 

3008
, and save the file.
Your code should look like the image below.

Lines 18-32 of template.yaml

Image: Lines 18-32 of template.yaml showing line 25 with MemorySize: 3008.

 Command: Redeploy your application by running the following commands in the AWS Cloud9 terminal.

sam build
sam deploy --no-confirm-changeset
 Note: These commands take up to 2 minutes to run.

 Expected output: Output has been truncated.


******************************
**** This is OUTPUT ONLY. ****
******************************

Your template contains a resource with logical ID "ServerlessRestApi", which is a reserved logical ID in AWS SAM. It could result in unexpected behaviors and is not recommended.
Building codeuri: /home/ec2-user/environment/app/product-api runtime: python3.7 metadata: {} architecture: x86_64 functions: ProductApiFunction
Running PythonPipBuilder:ResolveDependencies
Running PythonPipBuilder:CopySource

Build Succeeded

Built Artifacts  : .aws-sam/build
Built Template   : .aws-sam/build/template.yaml

Commands you can use next
=========================
[*] Validate SAM template: sam validate
[*] Invoke Function: sam local invoke
[*] Test Function in the Cloud: sam sync --stack-name {stack-name} --watch
[*] Deploy: sam deploy --guided
        
AWSLabsUser-rESsB5TBJBSaeePabTjJ3Q:~/environment/app $ sam deploy --no-confirm-changeset
File with same data already exists at product-api/a138bcfdeb1c25c132438ab4bb328799, skipping upload

        Deploying with following values
        ===============================
        Stack name                   : product-api
        Region                       : us-west-2
        Confirm changeset            : False
        Disable rollback             : False
        Deployment s3 bucket         : labstack-hornmarc-ressb5tbjbsaeep-generatedbucket-h439p5swrem6
        Capabilities                 : ["CAPABILITY_IAM"]
        Parameter overrides          : {"LambdaDeploymentRole": "arn:aws:iam::109726257434:role/LambdaDeploymentRole"}
        Signing Profiles             : {}

Initiating deployment
=====================



CloudFormation outputs from deployed stack
-----------------------------------------------
Outputs                                                                                                                                                                                                                      
-----------------------------------------------
Key                 ProductApiFunction                                                                                                                                                                                       
Description         Product Api Lambda Function ARN                                                                                                                                                                          
Value               arn:aws:lambda:us-west-2:109726257434:function:product-api-ProductApiFunction-Vmo75tFl4KRR                                                                                                               

Key                 ProductApiUrl                                                                                                                                                                                            
Description         API Gateway endpoint URL for Prod stage for Product Api function                                                                                                                                         
Value               https://vbcaer1v6d.execute-api.us-west-2.amazonaws.com                                                                                                                                                   
----------------------------------------------------

Successfully created/updated stack - product-api in us-west-2
Go back to the browser tab where the Locust application is running and, in the top navigation bar under STATUS STOPPED, start a new load test by choosing New Test.

Run a new test by choosing Start swarming with all of the previously entered values and let the load test run until you see, at the top of the screen, STATUS RUNNING 100 users.

To stop the load test, choose  Stop .

 Congratulations! According to the Statistics tab in Locust, you have decreased the average response time of the application. In the next task, you lower the maximum response times.

Task 4: Add provisioned concurrency to your Lambda function
In this task, you learn about cold starts and how to reduce or remove them from your application.

Lambda lifecycle timeline

Image: Shows the lifecycle of a Lambda function in four sequential steps: Download your code, Start new execution environment, Execute initialization code, and finally Execute handler code. The first two steps are in blue boxes indicating they are in the Cold start duration. The last two steps are in tan boxes indicating they are in the Invocation duration.

When the Lambda service receives a request to run a function through the Lambda API, four main actions happen:

The Lambda service downloads your code from an S3 bucket or a container registry depending on the packaging of your function.
Lambda creates an environment with the memory, runtime, and configuration that you have specified.
Lambda runs any initialization code outside the event handler.
Lambda runs the event handler code of your function.
The first two steps in the process outlined above are frequently referred to as a cold start. You are not charged for the time it takes for Lambda to prepare the function, but it does add latency to the overall invocation duration.

After the execution completes, the execution environment is frozen. To improve resource management and performance, the Lambda service retains the execution environment for a nondeterministic period of time. During this time, if another request arrives for the same function, the service may reuse the environment. This second request typically finishes more quickly, since the execution environment already exists and it’s not necessary to download the code and run the initialization code. This is called a warm start.

Cold starts can add significant response times to your application whenever Lambda has to start a new virtual machine (VM) to run an instance of your application. Provisioned concurrency can help this by always keeping a certain number of functions prewarmed.

When you ran your stress test, you noticed in the Lambda monitor tab that the maximum concurrency was approximately 40. Set the provisioned concurrency for your function to 40 to prevent cold starts.

In the AWS Cloud9 IDE, modify the template.yaml file by uncommenting lines 28-30:
Your code should look like the image below.

Lines 18-32 of template.yaml

Image: Lines 18-32 of template.yaml showing lines 28-30 are no longer commented out.

 Note: This configures an alias for your function called live. It also configures your Lambda function to have a provisioned concurrency of 40.

Save the changes to the template.yaml file.

 Command: Redeploy your application by running the following commands in a terminal window.


sam build
sam deploy --no-confirm-changeset
 Note: This deployment might take up to 5 minutes because of what AWS SAM is doing behind the scenes. Using provisioned concurrency requires versioning your Lambda application and providing an alias to the version.

 Expected output: Output has been truncated.


******************************
**** This is OUTPUT ONLY. ****
******************************

File with same data already exists at product-api/a138bcfdeb1c25c132438ab4bb328799, skipping upload

        Deploying with following values
        ===============================
        Stack name                   : product-api
        Region                       : us-west-2
        Confirm changeset            : False
        Disable rollback             : False
        Deployment s3 bucket         : labstack-hornmarc-ressb5tbjbsaeep-generatedbucket-h439p5swrem6
        Capabilities                 : ["CAPABILITY_IAM"]
        Parameter overrides          : {"LambdaDeploymentRole": "arn:aws:iam::109726257434:role/LambdaDeploymentRole"}
        Signing Profiles             : {}



Outputs                                                                                                                                                                                                                      
------------------------------------------------------
Key                 ProductApiFunction                                                                                                                                                                                       
Description         Product Api Lambda Function ARN                                                                                                                                                                          
Value               arn:aws:lambda:us-west-2:109726257434:function:product-api-ProductApiFunction-Vmo75tFl4KRR                                                                                                               

Key                 ProductApiUrl                                                                                                                                                                                            
Description         API Gateway endpoint URL for Prod stage for Product Api function                                                                                                                                         
Value               https://vbcaer1v6d.execute-api.us-west-2.amazonaws.com                                                                                                                                                   
------------------------------------------------------

Successfully created/updated stack - product-api in us-west-2
 Consider: Before running another load test, take a moment to review the Lambda function configuration in the AWS console.

Go back to the AWS console.

At the top of the AWS Management Console, in the search bar, search for and choose 

Lambda.

Choose the Lambda function that has product-api in the name.

In the middle of the screen below the Function overview section, choose the Configuration tab.

On the left side of the screen, choose General configuration.

Notice the Memory field. You should notice that this is the same value (3008 MB) that you set in Task 3.

On the left side of the screen, choose Concurrency.
Notice the values for Function concurrency and Unreserved account concurrency. Also note the Provisioned concurrency configurations section. This is where you can see the results of the configuration changes that you just made to the application.

Go back to the browser tab where the Locust application is running and, in the top navigation bar under STATUS STOPPED, start a new load test by choosing New Test.

Run a new test by choosing Start swarming with all of the previously entered values, and let the load test run until you see, at the top of the screen, STATUS RUNNING 100 users.

Choose  Stop to stop the load test.

What did you notice about your maximum response time after adding provisioned concurrency?

In the Max (ms) column on the Statistics tab in Locust, you notice that the maximum response times have been reduced by nearly 60%.
 Congratulations! You have successfully eliminated cold starts from your application.

Task 5: Add reserved concurrency to your Lambda function
In AWS, each account has a maximum Lambda concurrency limit of 1,000. This means that only 1,000 Lambda functions can run concurrently. In an environment where you might have several Lambda functions running at high concurrency, this can cause throttling if the concurrency limit has been used up and Lambda tries to start a new instance of your function.

In this task, to guarantee concurrency for your application, you use reserved concurrency. Reserved concurrency guarantees the maximum number of concurrent instances for the function.

Switch back to the Cloud9 browser tab.

Modify the template.yaml file by uncommenting line 31.

Your code should look like the image below.

Lines 18-32 of template.yaml

Image: Lines 18-32 of template.yaml showing line 31 is no longer commented out.

 Command: Redeploy your application by running the following commands in a terminal window.

sam build
sam deploy --no-confirm-changeset
 Expected output: The output has been truncated in this example.


******************************
**** This is OUTPUT ONLY. ****
******************************

CloudFormation outputs from deployed stack
------------------------------------------------------
Outputs                                                                                                                                                                                                                      
------------------------------------------------------
Key                 ProductApiFunction                                                                                                                                                                                       
Description         Product Api Lambda Function ARN                                                                                                                                                                          
Value               arn:aws:lambda:us-west-2:109726257434:function:product-api-ProductApiFunction-Vmo75tFl4KRR                                                                                                               

Key                 ProductApiUrl                                                                                                                                                                                            
Description         API Gateway endpoint URL for Prod stage for Product Api function                                                                                                                                         
Value               https://vbcaer1v6d.execute-api.us-west-2.amazonaws.com                                                                                                                                                   
------------------------------------------------------

Successfully created/updated stack - product-api in us-west-2
Go back to the browser tab where the Locust application is running and, in the top navigation bar under STATUS STOPPED, start a new load test by choosing New Test.

Run a new test by choosing Start swarming with all of the previously entered values and let the load test run until you see, at the top of the screen, STATUS RUNNING 100 users.

Choose  Stop to stop the load test.

 Congratulations! You have successfully configured the provisioned concurrency for your application.

Conclusion
 Congratulations! You now have successfully optimized your Lambda function. Your customers now experience decreased response times because you chose the proper memory size for you Lambda function. Your customers will no longer see increased wait times from cold starts because you configured provisioned concurrency for your Lambda function.

In this lab, you successfully did the following:

Deployed a Lambda function using AWS SAM.
Observed the performance characteristics of the Lambda function to determine possible performance enhancements.
Adjusted the memory size limit of a Lambda function to optimize performance.
Applied your knowledge of the Lambda function lifecycle to determine steps to optimize the function.
Configured provisioned concurrency and reserved concurrency on a Lambda function.
Used provisioned and reserved concurrency to optimize Lambda function performance.
