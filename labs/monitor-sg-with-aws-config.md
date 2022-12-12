Monitoring Security Groups with AWS Config

Overview
Amazon Elastic Compute Cloud (Amazon EC2) security groups are an important control for restricting access to your AWS infrastructure. In order to improve the effectiveness of this control, you can monitor the configuration of a security group for unauthorized changes. In this lab, you learn how to use AWS Config rules, together with an AWS Lambda function, to monitor the ingress ports associated with an EC2 security group. The Lambda function is invoked whenever the security group is modified. If the ingress rule configuration differs from what is in the Lambda function, the function reverts the ingress rules back to the appropriate configuration.

TOPICS COVERED
By the end of this lab, you will be able to:

Activate AWS Config
Create and activate a custom AWS Config rule
Verify the results of an AWS Config rule evaluation
TECHNICAL KNOWLEDGE PREREQUISITES
To successfully complete this lab, you should be familiar with EC2 security groups and basic navigation of the AWS Management Console.

WHAT IS AWS CONFIG?
AWS Config provides a detailed view of the configuration of AWS resources in your AWS account. This includes how the resources are related to one another and how they were configured in the past so that you can see how the configurations and relationships change over time. With AWS Config, you can do the following:

Evaluate your AWS resource configurations for desired settings.
Get a snapshot of the current configurations of the supported resources that are associated with your AWS account.
Retrieve configurations of one or more resources that exist in your account.
Retrieve historical configurations of one or more resources.
Receive a notification whenever a resource is created, modified, or deleted.
View relationships between resources. For example, you might want to find all resources that use a particular security group.
In this lab, you create a custom rule that invokes a Lambda function whenever changes are made to a security group. The Lambda function determines whether or not the ingress rules differ from a preconfigured pattern.

For further information about using AWS Config, see the official Amazon Web Services documentation at https://aws.amazon.com/documentation/config/. For pricing details, see https://aws.amazon.com/config/pricing/.

WHAT IS AWS LAMBDA?
AWS Lambda is a serverless compute service that provides resizable compute capacity in the cloud to make web-scale computing easier for developers. You can upload your code to Lambda and the service can run the code on your behalf using AWS infrastructure. Lambda supports multiple coding languages, such as Node.js, Java, Python, Go, .Net, and Ruby.

After you upload your code and create a Lambda function, AWS Lambda takes care of provisioning and managing the servers that you use to run the code. In this lab, you will use AWS Lambda as a trigger-driven compute service where AWS Lambda runs your code in response to changes to an Amazon EC2 security group. The code for the Lambda function will be provided in an S3 bucket.

For further information about using AWS Lambda, see the official Amazon Web Services documentation at https://aws.amazon.com/documentation/lambda/. For pricing details, see https://aws.amazon.com/lambda/pricing/.

Task 1: Review the Lambda IAM role and policy
During the lab environment provisioning process, an AWS Identity and Access Management (IAM) role and an IAM policy were created that define the permissions assigned to Lambda when it runs the function on your behalf. In this task, you review the details of the role and policy to better understand what the Lambda function is allowed to do.

At the top of the page, in the unified search bar, search for and choose 

IAM.

In the navigation pane at the left of the page, under Access management, choose Roles.

On the Roles page, select the link for the AwsConfigLambdaEc2SecuritygroupRole role to view its details.

On the AwsConfigLambdaEc2SecuritygroupRole details page, choose the Permissions tab, if it’s not selected already.

In the Permissions policies section, choose the  plus icon to the left of awsconfig_lambda_ec2_security_group_role_policy to view the details of the policy.

 The policy should contain a list of permissions in JSON format, similar to this:


{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*",
            "Effect": "Allow"
        },
        {
            "Action": [
            "config:PutEvaluations",
            "ec2:DescribeSecurityGroups",
            "ec2:AuthorizeSecurityGroupIngress",
            "ec2:RevokeSecurityGroupIngress"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
 The policy allows the Lambda function to perform the following actions:

For Amazon CloudWatch Logs:
Create a new log group (logs:CreateLogGroup).
Create a new log stream (logs:CreateLogStream).
Upload log events to a log stream (logs:PutLogEvents).
For AWS Config:
Deliver evaluation results to AWS Config (config:PutEvaluations).
For Amazon EC2:
Get the details of a security group (ec2:DescribeSecurityGroups).
Add ingress (inbound) rules of a security group (ec2:AuthorizeSecurityGroupIngress).
Delete ingress (inbound) rules of a security group (ec2:RevokeSecurityGroupIngress).
 Congratulations! You have successfully reviewed the IAM role that defines the actions that Lambda is allowed to use when running the function.

Task 2: Review and modify the AWS Config IAM role and policies
During the lab environment provisioning process, an IAM role and an IAM policy were created that define the permissions assigned to AWS Config when it performs monitoring tasks on your behalf. In this task, you review the details of the role and policy to better understand what AWS Config is allowed to do.

In the navigation pane at the left of the page, under Access management, choose Roles.

On the Roles page, select the link for the AwsConfigRole role to view its details.

On the AwsConfigRole details page, choose the Permissions tab, if it’s not selected already.

In the Permissions policies section, choose the  plus icon to the left of S3Access to view the details of the policy.

 The policy should contain a list of permissions in JSON format, similar to this:


{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Condition": {
                "StringLike": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            },
            "Action": [
                "s3:PutObject*"
            ],
            "Resource": [
                "arn:aws:s3:::*/AWSLogs/*/*"
            ],
            "Effect": "Allow"
        },
        {
            "Action": [
                "s3:GetBucketAcl"
            ],
            "Resource": "arn:aws:s3:::*",
            "Effect": "Allow"
        }
    ]
}
 The policy allows the AWS Config service to perform the following actions:

For Amazon Simple Storage Service (Amazon S3):
Upload objects and object properties, such as access permissions, to the AWSLogs folder within any bucket (s3:PutObject*).
Get the details of the bucket access control list (s3:GetBucketAcl).
In the Permissions policies section, choose Add permissions  and then choose Attach policies.

In the search box at the top of the Other permissions policies section, search for 

AWS_ConfigRole.

In the resulting list of policies, choose the  plus icon to the left of AWS_ConfigRole and review its policy elements.

Notice the policy allows read-type actions (Get, List, Describe) for various AWS services.

Select the checkbox to the left of AWS_ConfigRole.

Choose Attach policies.

 You attach the AWS_ConfigRole policy to grant permissions that allow AWS Config to determine the current state of security groups in the account.

Task 3: Monitor security groups with AWS Config
In this task, you set up AWS Config and configure it to monitor EC2 security groups.

At the top of the page, in the unified search bar, search for and choose 

Console Home.
 You return to the Console Home page to verify the region before visiting AWS Config. If you navigate directly to AWS Config from the IAM role details page, there is a chance that you are redirected to an incorrect AWS Region, which could cause difficulties in upcoming steps.

At the upper-right corner of the page, verify that the AWS Region matches the AwsRegionName value listed to the left of these instructions.

If the Region does not match, choose the correct one from the Region drop-down menu.

At the top of the page, in the unified search bar, search for and choose 

Config.

In the Set up AWS Config section, choose Get started.

On the Settings page, in the General settings section:

For Resource types to record, select Record specific resource types.
For Resource category, choose AWS resources.
For Resource type, choose AWS EC2 SecurityGroup.
For AWS Config role, select Choose a role from your account.
For Existing roles, choose AwsConfigRole.
 The AwsConfigRole IAM role contains the permissions you reviewed and added in the previous task.

In the Delivery method section:
For Amazon S3 bucket, select Create a bucket.
For S3 bucket name, keep the default value, which should look similar config-bucket-111122223333.
Leave the Prefix (optional) text box empty.
To the right of the Prefix text box, notice the default prefix (file path) is similar to /AWSLogs/111122223333/Config/us-west-2. Remember, when you reviewed the AwsConfigRole IAM role previously, you discovered that it allows AWS Config to upload objects (s3:PutObject) to the AWSLogs directory of any bucket (arn:aws:s3:::*/AWSLogs/*/*).

At the bottom of the page, choose Next.

On the Rules page, keep the defaults (no selections), and then, at the bottom of the page, choose Next.

On the Review page, confirm your selected settings, and then choose Confirm.

You should notice two messages at the top of the page—one stating the S3 bucket was created successfully, and another stating Successfully signed up with AWS Config. After approximately 10 seconds, you are then redirected to the AWS Config Dashboard page.

On the Dashboard page, in the navigation pane at the left of the page, choose Resources.
 There are two Resources options in the navigation pane. Choose the one outside of the Aggregators section.

On the Resource Inventory page:
For Resource type, choose All resource types, if it’s not selected already.
Notice that many resource types other than EC2 SecurityGroup appear in the list of resources, even though you did not select them when you initially configured AWS Config. Because related resources can affect the behavior of the primary resource(s) you want to monitor, AWS Config also monitors those resources.

 Congratulations! You have successfully configured AWS Config to monitor EC2 security groups.

Task 4: Modify the EC2 security group
In this task, you modify security group rules to give AWS Config a configuration change to identify.

At the top of the page, in the unified search bar, search for and choose 

EC2.

In the navigation pane at the left of the page, under Network & Security, choose Security Groups.

Select the link for the Security group ID that matches the LabVpcSgId value listed to the left of these instructions.

The security group you just selected is the default security group for the Lab VPC VPC.

On the security group Details page, choose the Inbound rules tab, if it’s not selected already.
Notice there is currently one inbound rule that allows traffic on all ports from any source. By default, when you create a VPC, a security group is automatically created that allows all inbound and outbound traffic, which is referred to as the default security group.

Choose Edit inbound rules.

On the Edit inbound rules page, choose Add rule.

In the row for the new rule:

For Type, choose HTTP.
Notice Protocol and Port range are automatically set to TCP and 80, respectively.
For Source, choose Anywhere-IPv4.
Repeat the previous steps to add three more rules with the following settings:
Rule 1:
Type: HTTPS
Source: Anywhere-IPv4
Rule 2:
Type: SMTPS
Source: Anywhere-IPv4
Rule 3:
Type: IMAPS
Source: Anywhere-IPv4
 You should now have four inbound rules.

At the bottom of the page, choose Save rules.
 Congratulations! You have successfully modified the inbound rules of the default security group attached to the lab VPC.


Task 5: Create and run an AWS Config rule
In this task, you create an AWS Config rule to monitor security groups and validate that they have a specific configuration. You configure the rule to use a Lambda function that is able to add and remove security group rules maintain the desired inbound rule state.

At the top of the page, in the unified search bar, search for and choose 

Config.

At the upper-right corner of the page, verify that the AWS Region matches the AwsRegionName value listed to the left of these instructions.

On the Dashboard page, in the navigation pane at the left of the page, choose Rules.

 There are two Rules options in the navigation pane. Choose the one outside of the Aggregators section.

There should currently be no rules listed.

Choose Add rule.

On the Specify rule type page:

For Select rule type, select Create custom Lambda rule.
Choose Next.

On the Configure rule page, in the Details section:

For Name, enter 

EC2SecurityGroupConfigRule.
For Description, enter 

Restrict ingress ports to HTTP and HTTPS.
For AWS Lambda function ARN, copy and paste the LambdaFunctionArn value listed to the left of these instructions.
 The Lambda function you reference by ARN in this step was created for you during the lab environment provisioning process. The Python code in the function contains the following section labeled REQUIRED_PERMISSIONS:


REQUIRED_PERMISSIONS = [
{
    "IpProtocol" : "tcp",
    "FromPort" : 80,
    "ToPort" : 80,
    "UserIdGroupPairs" : [],
    "IpRanges" : [{"CidrIp" : "0.0.0.0/0"}],
    "PrefixListIds" : [],
    "Ipv6Ranges": [
        {
            "CidrIpv6": "::/0"
        }
    ]
},
{
    "IpProtocol" : "tcp",
    "FromPort" : 443,
    "ToPort" : 443,
    "UserIdGroupPairs" : [],
    "IpRanges" : [{"CidrIp" : "0.0.0.0/0"}],
    "PrefixListIds" : [],
    "Ipv6Ranges": [
        {
            "CidrIpv6": "::/0"
        }
    ]
}]
It is an array of desired ingress rules in the format used by the describe_security_groups() API call and used later in the code. Notice that the array only contains rules for HTTP (TCP port 80) and HTTPS (TCP port 443). It does not include the rules you added for SMTPS (TCP port 465) and IMAPS (TCP port 993) in the previous task. Also notice that IPv4 (0.0.0.0/0) and IPv6 (::/0) ranges are both specified.

If the ingress permissions contain anything other than the permissions in this array, the code uses the authorize_security_group_ingress() and revoke_security_group_ingress() calls to add or remove permissions as appropriate. Therefore, if this function works as expected, it should remove the SMTPS (TCP port 465) and IMAPS (TCP port 993) rules from the security group when it is invoked.

In the Evaluation mode section:
For Trigger type, select When configuration changes.
For Scope of changes, select Resources.
For Resource category, choose AWS resources.
For Resource type, choose AWS EC2 SecurityGroup
Keep the remaining default values, and then, at the bottom of the page, choose Next.

On the Review and create page, review the configuration details, and then choose Add rule.

At the top of the Rules page, you should notice a green banner with the following message:

The rule: EC2SecurityGroupConfigRule has been added to your account

In the Rules section, for EC2SecurityGroupConfigRule, the Compliance column should display a status of Compliant.
 It can take approximately 2-3 minutes for the compliance status to change while the rule is being evaluated and the Lambda function is run. If the rule or the compliance status are not displayed, use your web browser’s refresh button to refresh the page.

 Congratulations! You have successfully created an AWS Config rule that uses a Lambda function to maintain a set of inbound rules for a security group.

Task 6: Verify the security group rules
Now that you have created the AWS Config rule to monitor the configuration of your security groups, you can examine the inbound rules you created in a previous task. If the AWS Config rule and associated Lambda function worked as expected, you should notice further changes have been made to the inbound rules.

At the top of the page, in the unified search bar, search for and choose 

EC2.

In the navigation pane at the left of the page, under Network & Security, choose Security Groups.

Select the link for the Security group ID that matches the LabVpcSgId value listed to the left of these instructions.

The security group you just selected is the default security group for the Lab VPC VPC.

On the security group Details page, choose the Inbound rules tab.
Notice that are now four rules total:

Allow HTTP (port 80) traffic from any IPv4 source
Allow HTTP (port 80) traffic from any IPv6 source
Allow HTTPS (port 443) traffic from any IPv4 source
Allow HTTPS (port 443) traffic from any IPv6 source
The new inbound rules set corresponds to the REQUIRED_PERMISSIONS that were configured in the Lambda function code. The Lambda function detected the additional permissions for SMTPS (TCP port 465) and IMAPS (TCP port 993) that were present in the security group and removed them. It also added the HTTP and HTTPS rules for IPv6 sources.

In this example, the difference in configuration was detected during the initial AWS Config rule validation. If you were to modify the security group again, it would initiate a new compliance evaluation, which would again invoke the Lambda function and the changes would be reverted.

 Challenge yourself! Make another change to the security group inbound rules and then observe the results. Do the rules always get set back to allowing only HTTP and HTTPS connections?

 It can take approximately 3 minutes for the AWS Config rule to re-evaluate the security group change

 Congratulations! You have successfully verified that the AWS Config rule and associated Lambda function have modified the security group inbound rules to match the desired state.

Conclusion
 Congratulations! You now have successfully:

Activated AWS Config
Modified the default VPC security group to contain both compliant and noncompliant permissions
Activated an AWS Config rule and observed the results