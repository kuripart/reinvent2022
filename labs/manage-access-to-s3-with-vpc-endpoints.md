Managing Access to Amazon S3 Resources with Amazon VPC Endpoints

Lab overview
Amazon Virtual Private Cloud (Amazon VPC) endpoints allow you to provide Amazon Elastic Compute Cloud (Amazon EC2) instances controlled access to Amazon Simple Storage Service (Amazon S3) buckets, objects, and Application Programming Interface (API) functions without requiring an Internet gateway or Network Address Translation (NAT) device. In this lab, you implement an Amazon VPC endpoint to facilitate communications between an Amazon EC2 instance in a private subnet and an Amazon S3 bucket. You also create a bucket policy to only allow connections to the S3 bucket through the VPC endpoint.

TOPICS COVERED
By the end of this lab, you will be able to:

Implement VPC endpoints to facilitate communications between an EC2 instance in a private subnet and an S3 bucket.
Create a bucket policy to only allow connections to a bucket through a VPC endpoint.
Turn on Amazon S3 Versioning for a bucket.
Restore a deleted object.
TECHNICAL KNOWLEDGE PREREQUISITES
To successfully complete this lab, you should have general familiarity with AWS, as covered in the AWS Cloud Practitioner Essentials course, and be familiar with basic navigation of the AWS Management Console.

ICON KEY
Various icons are used throughout this lab to call attention to certain aspects of the guide. The following list explains the purpose for each one:

 The keyboard icon specifies that you must run a command.
 The clipboard icon indicates that you can verify the output of a command or edited file by comparing it to the provided example.
 The note icon specifies important hints, tips, guidance, or advice.
 Calls attention to information of special interest or importance. Failure to read the note does not result in physical harm to the equipment or data, but could result in the need to repeat certain steps.
 Draws special attention to actions that are irreversible and could potentially impact the failure of a command or process. Includes warnings about configurations that cannot be changed after they are made.
 The “i” circle icon specifies where to find more information.
 The person with a check mark icon indicates an opportunity to check your knowledge and test what you have learned.
 Suggests a moment to pause to consider how you might apply a concept in your own environment or to initiate a conversation about the topic at hand.
SCENARIO
You work for a healthcare organization that is using Amazon S3 for internal customer data storage. Your team is responsible for implementing a solution to share reports between a sales application and a reports storage repository. The application writes daily reports to Amazon S3 for further analysis. Your team’s leadership has mandated that these reports should not be accessible over public internet connections. You need to ensure that this information is transmitted across private network segments only. The reports in the S3 buckets should be protected against accidental deletion. You plan to meet this requirement by implementing VPC endpoints and versioning.

Task 1: Environment overview
In this task, you review the lab environment to gain a better understanding of what you will be working with throughout the course of the lab.

The following diagram shows the basic architecture of the lab environment:

The architecture diagram of the lab environment, which shows an Amazon VPC with one public subnet, one private subnet, one EC2 instance in each subnet, a VPC endpoint, and one S3 bucket named daily-reports. The diagram depicts an external user connecting to the public instance, then connecting to the private instance from the public instance. Data flows from the private instance through the VPC endpoint to the S3 bucket, then flows back from the bucket through the VPC endpoint to the private instance

The following list details the major resources in the diagram:

Deployed during the lab environment build process:
Public and private subnets in an Amazon Virtual Private Cloud (Amazon VPC).
Amazon Elastic Compute Cloud (Amazon EC2) instances. There is one Amazon EC2 instance in each subnet. Network access is restricted to only the traffic required to complete this lab. The instance in the public subnet serves as a bastion host that you use to connect to the instance in the private subnet.
daily-reports S3 bucket, which you configure to allow only access from the VPC endpoint.
Added during completion of the lab:
A VPC Endpoint, which is used to grant access from the private EC2 instance to the S3 bucket.
TASK 1.1: EXAMINE THE EC2 INSTANCES
First, examine the two EC2 instances that were provisioned during the lab build process.

If you have not already done so, follow the steps in the Start Lab section to log into the AWS Management Console.

At the top of the page, in the unified search bar, search for and choose 

EC2.

In the navigation pane at the left of the page, choose Instances.

Notice there are two instances, Public Instance and Private Instance.

Select Public Instance and verify it is the only item selected.

In the details pane at the bottom of the window, on the Details tab, review the VPC ID, Subnet ID, and Public IPv4 address.

 You can use the screen real estate buttons Image of the three screen real estate squares at the right side of the details pane to easily expand or collapse it.

 The public instance resides in the Lab Public Subnet, which is in the Lab VPC. It has both a public and private IP address.

Select Private Instance and verify it is the only item selected.

At the bottom of the page, on the Details tab, review the VPC ID, Subnet ID, and Public IPv4 address.

 The private instance resides in the Lab Private Subnet, which is in the Lab VPC. It does not have a public IP address, only a private IP address.

Notice that both instances reside in the same VPC.

TASK 1.2: EXAMINE THE SECURITY GROUPS
Next, review the security group configuration for each instance.

In the navigation pane at the left of the page, under Network & Security, choose Security Groups.

On the Security Groups page, select Public Instance SG and verify it is the only item selected.

At the bottom of the page, choose the Inbound rules tab to review the inbound traffic rules for the public instance.

 Notice there are no inbound traffic rules. Because you use AWS Systems Manager Session Manager to connect to the public instance, it is not necessary to allow SSH traffic to the instance.

Choose the Outbound rules tab to review the outbound traffic rules for the public instance.
 The security group allows outbound traffic on the following ports and protocols:

HTTP on port 80 and HTTPS on port 443 to any IP address, which allows for communication with other AWS Services.
SSH on port 22 to any address in the 10.10.2.0/24 subnet, which is the lab private subnet, and allows the public instance to SSH to the private instance.
Next, review the security group configuration for the private instance.

In the list of security groups, select Private Instance SG and verify it is the only item selected.

At the bottom of the page, choose the Inbound rules tab to review the inbound traffic rules for the public instance.

 Notice that inbound traffic is limited to SSH on port 22 from the 10.10.1.0/24 subnet, which is the lab public subnet, and allows the public instance to SSH to the private instance.

Choose the Outbound rules tab to review the outbound traffic rules for the public instance.
 The security group allows outbound traffic on HTTP on port 80 and HTTPS on port 443 to any IP address, which allows for communication with other AWS Services.

TASK 1.3: EXAMINE THE S3 BUCKET
Next, review the daily-reports S3 bucket configuration.

At the top of the page, in the unified search bar, search for and choose 

S3.

On the Amazon S3 Buckets page, choose the link for the bucket name that starts with daily-reports.

On the daily-reports details page, notice the bucket does not contain any objects.

Choose the Permissions tab.

On the Permissions tab, review the security settings for the bucket. Notice that Block all public access is turned on and there are no bucket policies. Since all public access is blocked, only your account has access to the bucket and objects within it. For the purposes of this lab, you access the objects using the AWS Management Console and an Amazon EC2 instance.
 Now that you have a better understanding of the lab environment, attempt to access the S3 bucket from the private instance.

TASK 1.4: CONNECT TO THE PRIVATE INSTANCE
Remember from the scenario, the requirement is that the data in the S3 bucket can not be accessed from any public source. You interact with the S3 bucket from the private instance, but you use the public instance as a bastion host and connect to the private instance through it.

First, connect to the public instance.

At the top of the page, in the unified search bar, search for and choose 

EC2

In the navigation pane at the left of the page, choose Instances.

Select the Public Instance and then, at the top-right of the page, choose Connect

On the Connect to instance page, choose the Session Manager tab, and then choose Connect

 A new browser tab opens with a console connection to the instance. A set of commands are run automatically when you connect to the instance that change to the user’s home directory and display the path of the working directory, similar to this:


cd HOME; pwd
sh-4.2$ cd HOME; pwd
/home/ec2-user
sh-4.2$
Next, connect to the private instance from the public instance. In this lab, you use EC2 Instance Connect to create an SSH connection to the private instance.

 For more information, refer to EC2 Instance Connect in the Additional resources section.

 Enter the following command to connect to the Private instance via EC2 Instance Connect:
Replace INSTANCE_ID with the value of PrivateInstanceId listed to the left of these instructions.
Replace REGION with the value of AwsRegion listed to the left of these instructions.

mssh -o ServerAliveInterval=120 INSTANCE_ID -r REGION
 The -o tag sends a message between the two hosts at the specified interval, in seconds, to keep the SSH connection open.

On a Windows-based computer, use Ctrl + Shift + V to paste text into a Session Manager console window.

 The output states that the authenticity of the host can’t be established and asks if you want to continue connecting to the host.

 Enter 

yes
 Notice the prompt changes from sh-4.2 to ec2-user@ip with the IP address of the private instance, which is in the 10.10.2.0/24 subnet.

 Enter the following command to create a text file to test file uploads to the bucket:

touch test.txt
 Enter the following command to copy the test.txt file to the daily-reports bucket:
Replace BUCKET with the value of Bucket listed to the left of these instructions.

aws s3 cp test.txt s3://BUCKET/test.txt
 The command times out after approximately five minutes because there is currently no path for the traffic from the private instance to the bucket. If you don’t want to wait for the timeout, press 

Ctrl + C
 to cancel the command.

 The output message is similar to this, though the bucket name may differ:


upload failed: ./test.txt to s3://daily-reports-375010115/test.txt Connect timeout on endpoint URL: "https://daily-reports-375010115.s3.amazonaws.com/test.txt"
Now that you have a better understanding of the lab environment you can begin to configure the services required to establish the connection from the private instance to the bucket.

Task 2: Create a VPC endpoint
Because you don’t want the objects in the daily-reports bucket to be accessible over public internet connections, you decide to create a VPC endpoint. The VPC endpoint allows for a private connection between your VPC and the S3 service.

 For more information about VPC endpoints, refer to VPC endpoints in the Additional resources section.

TASK 2.1: CREATE A VPC ENDPOINT
Return to your browser tab with the AWS Management Console.

At the top of the page, in the unified search bar, search for and choose 

VPC.

In the navigation pane at the left of the page, under VIRTUAL PRIVATE CLOUD, choose Endpoints.

At the top of the page, choose Create Endpoint

On the Create Endpoint page:

For Service category, choose AWS services.
For Service name, search for 

s3
 and then select the item with a Type of Gateway. The entry looks similar to this:
com.amazonaws.us-west-2.s3 | amazon | Gateway
For VPC, select Lab VPC.
For Configure route tables, select the Route Table ID with an Associated With value of Lab Private Subnet.
For Policy, select Custom, and then copy and paste the following policy into the empty text box:
Replace BUCKET with the value of Bucket listed to the left of these instructions.
 There is one instance of BUCKET.

{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:DeleteObject",
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": "arn:aws:s3:::BUCKET/*"
        }
    ]
}
 The policy you just applied allows any resource within your VPC to delete or get objects from, or put objects to, the daily-reports bucket.

 For more information about creating VPC endpoint policies for use with S3, refer to Endpoint policies for Amazon S3 in the Additional resources section.

 The final endpoint policy should look similar to this:


{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:DeleteObject",
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": "arn:aws:s3:::daily-reports-375010115/*"
        }
    ]
}
At the bottom of the page, choose Create endpoint
You should receive a message stating the VPC endpoint was created.

Choose Close

Select the VPC endpoint you just created.

In the details pane at the bottom of the window, on the Details tab, copy the Endpoint ID and paste it into a text editor of your choosing. You use it in a future task when creating the bucket policy.

TASK 2.2: OBSERVE THE CHANGE IN THE PRIVATE SUBNET ROUTE TABLE
When you created the VPC endpoint, you specified that it should interface with the private subnet. To do so, a new route is added to the private subnet route table that directs all traffic for Amazon S3 to the endpoint.

In the navigation pane at the left of the page, under VIRTUAL PRIVATE CLOUD, choose Route Tables.

Select PrivateRouteTable.

At the bottom of the page, choose the Routes tab.

Verify that there are two entries in the route table—one for the local network and one that the VPC endpoint created. It should look similar to the following table, though your VPC endpoint entry will differ:

 If the second route is not displayed, wait one minute and then refresh the page.

Destination	Target	Status	Propagated
10.10.0.0/16	local	 Active	No
pl-68a54001	vpce-05d2a4c5129d8df74	 Active	No
Make a note of the prefix ID, which starts with pl-.

Next, observe the details of the route in the managed prefix list.

In the navigation pane at the left of the page, choose Managed Prefix Lists.

On the Managed prefix lists page, select the entry with a Prefix list name that ends in s3.

Notice that it is named for the Amazon S3 service in the region you are working in. The Prefix list ID should match the one listed in the private route table.

In the details pane at the bottom of the window, choose the Entries tab.
Notice there are a number of predefined IP ranges listed, which are associated with the Amazon S3 service in the region you are working in.

 Because you selected AWS services as the service category for your VPC endpoint, the prefix list on this page is managed by AWS. You do not need to know the correct IP addresses for the Amazon S3 service to properly create the route. Refer to Prefix lists in the Additional resources section for more information.

 Congratulations! You have successfully created a VPC endpoint to allow access from resources inside the VPC to the S3 bucket.

Task 3: Create a bucket policy
In this task, you create a bucket policy to only allow connections to the bucket from the VPC.

At the top of the page, in the unified search bar, search for and choose 

S3.

On the Amazon S3 Buckets page, choose the link for the bucket name that starts with daily-reports.

Choose the Permissions tab.

In the Bucket policy section, choose Edit

On the Edit bucket policy page, in the Policy section, copy and paste the following policy:

Replace BUCKET with the value of Bucket listed to the left of these instructions.
Replace VPCE_ID with the Endpoint ID of the VPC endpoint that you created previously.
 There is one instance of BUCKET and one instance of VPCE_ID.

{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Deny",
            "Principal": "*",
            "Action": [
                "s3:DeleteObject",
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": "arn:aws:s3:::BUCKET/*",
            "Condition": {
                "StringNotEquals": {
                    "aws:sourceVpce": "VPCE_ID"
                }
            }
        }
    ]
}
 The policy you just applied denies any source from performing the DeleteObject, GetObject, and PutObject actions unless the request originates from the VPC endpoint you specified.

 Because the S3 bucket policy denies the actions listed unless the request is sent through the VPC endpoint, be very careful with the actions you list. For example, if you were to use s3:* in the action list, you would be unable to interact with the bucket through the AWS Management Console in any way. The only way to recover from a scenario like that would be to use the AWS CLI from an instance that is in the subnet identified in the VPC endpoint configuration, or by contacting AWS support.

With the policy you just applied, you are not able to delete, download, or upload objects from any source other than the private instance. If you attempt to do so from the S3 console, you receive an access denied message.

 For more information about Amazon S3 bucket policies, refer to Policies and permissions in Amazon S3 in the Additional resources section.

 The final bucket policy should look similar to this:


{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Deny",
            "Principal": "*",
            "Action": [
                "s3:DeleteObject",
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": "arn:aws:s3:::daily-reports-375010115/*",
            "Condition": {
                "StringNotEquals": {
                    "aws:sourceVpce": "vpce-0bf0c9c75b82ceff9"
                }
            }
        }
    ]
}
At the bottom of the page, choose Save changes
 Congratulations! You have successfully created a bucket policy to allow access to objects only from sources within the VPC.

Task 4: Test connectivity and add instance permissions
You have created the VPC endpoint and bucket policies to allow only the necessary S3 actions from sources within the private subnet. Next, test the connection to verify the configuration works as intended.

TASK 4.1: TEST CONNECTIVITY TO THE BUCKET FROM THE PRIVATE INSTANCE
Return to your browser tab with the AWS Systems Manager - Session Manager connection.

Verify the prompt indicates you are connected to the private instance. It should display as ec2-user@ip with the IP address of the private instance.

 Enter the following command to copy the test.txt file to the daily-reports bucket:

Replace BUCKET with the value of Bucket listed to the left of these instructions.

aws s3 cp test.txt s3://BUCKET/test.txt
 The output should display an Access Denied message, similar to this:


upload failed: ./test.txt to s3://daily-reports-375010115/test.txt An error occurred (AccessDenied) when calling the PutObject operation: Access Denied
 What might cause the request to generate an access denied message, even though you have configured the VPC endpoint and bucket policy correctly?

In this case, the IAM role attached to the EC2 instance does not have the appropriate permissions to perform the PutObject action. To resolve the issue, you can modify the IAM role that is attached to the instance, or you can attach a new one. In this lab, you attach a new role.

TASK 4.2: ATTACH A ROLE WITH APPROPRIATE PERMISSIONS TO THE PRIVATE INSTANCE
Return to your browser tab with the AWS Management Console.

At the top of the page, in the unified search bar, search for and choose 

EC2.

In the navigation pane at the left of the page, choose Instances.

Select the Private Instance.

At the top-right of the page, choose Actions 

On the Actions drop-down menu, choose Security, and then choose Modify IAM role.

On the Modify IAM role page, for IAM role, select S3AccessProfile.

 The role you just selected is an IAM instance profile that was created during the lab environment build process. It allows the instance to perform the same S3 actions that you configured in the VPC endpoint and S3 bucket policies, and looks similar to this:


{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "s3:Delete:Object",
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Effect": "Allow",
            "Resource": "arn:aws:s3:::daily-reports-375010115/*"
        }
    ]
}
Choose Save
TASK 4.3: RETEST CONNECTIVITY TO THE BUCKET
Now that you have attached an IAM role with the appropriate permissions to the private instance, attempt to upload a file to the bucket again to verify it works as intended.

Return to your browser tab with the AWS Systems Manager - Session Manager connection.

 Enter the following command to copy the test.txt file to the daily-reports bucket:

Replace BUCKET with the value of Bucket listed to the left of these instructions.

aws s3 cp test.txt s3://BUCKET/test.txt
 The output should now display a message indicating the upload succeeded, similar to this:


upload: ./test.txt to s3://daily-reports-375010115/test.txt
 Congratulations! You have successfully applied an IAM instance profile with an IAM role that contains the correct permissions to upload files to the bucket.

Task 5: Turn on S3 Versioning for the bucket and explore the effects
You have successfully connected to an Amazon S3 bucket from an EC2 instance on a private network, which meets the first requirement of the scenario. Currently, if you delete an object from the bucket, or overwrite it with an object of the same name, the existing version would be lost. In this task, you turn on and explore Amazon S3 bucket versioning to meet the requirement to protect objects against accidental deletion.

TASK 5.1: TURN ON VERSIONING
Return to your browser tab with the AWS Management Console.

At the top of the page, in the unified search bar, search for and choose 

S3
.

On the Amazon S3 Buckets page, choose the link for the bucket name that starts with daily-reports.

Choose the Properties tab.

In the Bucket Versioning section, choose Edit

In the Edit Bucket Versioning page, for Bucket Versioning, select Enable.

Choose Save changes

 When you turn on versioning for a bucket, existing objects remain unchanged. When you upload an object after versioning is turned on, a version ID is assigned to that version of the object to distinguish it from other versions of the same object. For more information, refer to How S3 Versioning works in the Additional resources section.

Choose the Objects tab.

Above the list of objects and to the right of the search field, choose the Show versions switch to toggle it on.

Notice a new column named Version ID appears. The test.txt file you uploaded previously has a version ID of null because you uploaded it to the bucket before you turned on versioning.

TASK 5.2: UPLOAD THE TEST FILE AGAIN AND OBSERVE THE RESULTS
Return to your browser tab with the AWS Systems Manager - Session Manager connection.

Verify the prompt indicates you are connected to the private instance. It should display as ec2-user@ip with the IP address of the private instance.

 Enter the following command to copy the test.txt file to the daily-reports bucket:

Replace BUCKET with the value of Bucket listed to the left of these instructions.

aws s3 cp test.txt s3://BUCKET/test.txt
Return to your browser tab with the AWS Management Console. You should be on the daily-reports bucket details page.

With Show versions on, verify there are now two versions of test.txt listed—the original version with the null version ID, and a new one with a version ID assigned to it.

 You may need to choose the refresh button  to refresh the list of objects.

Now that you have observed S3 Versioning in action, experiment with file deletions and recovery.

TASK 5.3: DELETE THE TEST FILE AND OBSERVE THE RESULTS
Return to your browser tab with the AWS Systems Manager - Session Manager connection.

Verify the prompt indicates you are connected to the private instance. It should display as ec2-user@ip with the IP address of the private instance.

 Enter the following command to delete the test.txt file from the daily-reports bucket:

Replace BUCKET with the value of Bucket listed to the left of these instructions.

aws s3 rm s3://BUCKET/test.txt
 The output should indicate the delete succeeded, similar to this:


delete: s3://daily-reports-375010115/test.txt
Return to your browser tab with the AWS Management Console. You should be on the daily-reports bucket details page.

With Show versions on, verify the latest version of the test.txt object has a Type of Delete marker.

 You may need to choose the refresh button  to refresh the list of objects.

 When you delete an object from a bucket with versioning turned on, the object is not actually deleted. Instead, a delete marker is created as the new version of the object. You can view the delete markers when the show versions option is turned on in the S3 console. However, if show versions is turned off, the object is not displayed. For more information about delete markers, refer to Working with delete markers in the Additional resources section.

Choose the Show versions switch to toggle it off.
Notice that the test.txt object is no longer displayed.

When you deleted the object, you observed that a delete marker was created as the latest version of the object. If you attempt to perform a GET operation, or download, the object, you would receive a message stating the object does not exist. How might you restore the file?

TASK 5.3: RESTORE THE DELETED FILE
To restore a deleted object, simply delete the delete marker.

Choose the Show versions switch to toggle it on. The test.txt versions are now displayed.

Select the most recent version of the test.txt file, which has a Type of Delete marker.

Above the list of objects, choose Delete

On the Delete objects page:

For Permanently delete objects?, enter 

permanently delete

At the bottom of the page, choose Delete objects

At the top-right corner of the Delete object: status page, choose Close
Notice the delete marker is removed and the previous version becomes the current version.

Choose the Show versions switch to toggle it off. The test.txt object is now displayed and could be downloaded with a GET operation.
 Congratulations! You have successfully observed how deletions work in an S3 bucket with versioning turned on, and how to restore a deleted object.

Conclusion
 Congratulations! You now have successfully:

Implemented VPC endpoints to facilitate communications between an EC2 instance in a private subnet and an S3 bucket.
Created a bucket policy to only allow connections to a bucket through a VPC endpoint.
Turned on Amazon S3 Versioning for a bucket.
Restored a deleted object.
Additional resources
EC2 Instance Connect
VPC endpoints
Endpoint policies for Amazon S3
Prefix lists
Policies and permissions in Amazon S3
How S3 Versioning works
Working with delete markers