Troubleshooting connectivity using EC2 Serial Console

Overview and scenario
As a network administrator for Example Corp, you have been tasked with deploying a Linux FTP server that employees and contractors can use to exchange files securely. During the configuration process, you encounter problems and use the EC2 Serial Console to remediate them.

As you work through these issues, you will learn how to enable Serial Console access for an account, grant Serial Console permissions, and connect to an instance using Serial Console.

This lab makes use of the following AWS tools and services:

Amazon Elastic Compute Cloud (Amazon EC2)

Amazon EC2 is a web service that provides resizable compute capacity in the cloud. It’s designed to make web-scale cloud computing easier for developers. Amazon EC2 reduces the time required to obtain and boot a new server instance to minutes, allowing you to quickly scale capacity, both up-and-down, as your computing requirements change.
 Learn more about Amazon EC2
EC2 Instance Connect

Amazon EC2 Instance Connect is a simple and secure way to connect to your instances using Secure Shell (SSH).
 Learn more about Amazon EC2 Instance Connect
AWS Systems Manager Parameter Store

AWS Systems Manager Parameter Store provides secure, hierarchical storage for configuration data management and secrets management. The IDs of the user pool and the web application have been stored in the Systems Manager’s Parameter Store.
 Learn more about AWS Systems Manager’s Parameter Store
Objectives
After completing this lab, you will be able to:

Configure an FTP server using vsftpd and firewalld.
Enable Serial Console at the account level.
Connect to an EC2 instance using Serial Console.
Use Remote Desktop (RDP) to connect to an Amazon EC2 instance running Windows Server
Prerequisites
To successfully complete this lab, you should be familiar with Linux, networking, and have a basic knowledge of AWS. You will also need a remote desktop client installed on your local machine.

How to install an RDP client:

Windows includes an RDP client by default. To verify, type 

mstsc
 at a Command Prompt window. If your computer doesn’t recognize this command, see the Windows home page and search for the download for the Microsoft Remote Desktop app.
Mac users can Download the Microsoft Remote Desktop app from the Mac App Store.
A variety of DRP clients, including Remmina are available for Linux users.
Duration
This lab takes approximately 60 minutes to complete. You are allotted a total of 90 minutes to complete this lab.

Task 1: Connect to the FTP Host
In this task, you connect to an Amazon Linux EC2 instance using EC2 Instance Connect. Throughout the lab, this instance is referred to as the ftpHost.

If you have not already done so, follow the steps in the Start Lab section to log in to the AWS Management Console.

In the search box to the right of  Services, search for and choose EC2 to open the Amazon EC2 console.

 If you are not brought to the EC2 Dashboard, choose the EC2 Dashboard link on the left side of the screen.

On the EC2 Dashboard, choose Instances (running).

Select the checkbox next to ftpHost instance and then choose Connect

You are brought to the Connect to instance page. Open the EC2 Instance Connect tab, verify that the User name is set to ec2-user and choose Connect

 EC2 Instance Connect enables you to connect to instances that have public or private IP addresses using SSH. All SSH keys are managed by AWS Identity and Access Management, which means you never have to worry about sharing or managing them.

A new browser tab or window opens with a connection to the ftpHost.

 Enter the following command to confirm that you are in the ec2-user’s home directory:

pwd
Confirm that you are in the following directory:


/home/ec2-user
Task 2: Install and configure vsftpd
In this task, you will download, install, and configure very secure FTP daemon (vsftpd). vsftpd is a light-weight and highly secure FTP server.

 Enter the following command to update the YUM package manager:

sudo yum update -y
 Now that you’ve updated YUM, install the vsftpd server:

sudo yum install vsftpd -y
Review the output to confirm that the installation was successful. The bottom of the output should look similar to this:

Installed:
  vsftpd.aarch64 0:3.0.2-25.amzn2

Complete!
 The vsftpd.conf file defines parameters that are used to configure the vsftpd server. For the purposes of this lab, a modified .conf file has been created for you.

 Use the less command to review the .conf file:

less +G myvsftpd.conf
 The codeblock below displays displays the end of the myvsftpd.conf file, where most of the custom options have been written.


chroot_list_enable=YES
chroot_list_file=/etc/vsftpd.chroot_list
listen=YES
pam_service_name=vsftpd
allow_writeable_chroot=YES
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=41000
The configuration file contains the following settings that are important for this lab:


chroot_list_enable=YES
 enables a chroot jail that locks FTP users to their home directory on the server.

chroot_list_file=/etc/vsftpd.chroot_list
 specifies the location of the list of users who are permitted to access the server.

pasv_enable=YES
 enables data transfer over ephemeral ports.

pasv_min_port=40000
 and 

pasv_max_port=41000
 define the ephemeral ports used for data transfer.
Next, we will replace the standard vsftpd.conf file with our customized file.

Press the q button to exit less and return to the command prompt.

 Next, create a backup of the original .conf file:


sudo mv /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.bak
 Now, replace the original .conf file with the customized file:

sudo cp ~/myvsftpd.conf /etc/vsftpd/vsftpd.conf
 We need to create a new user who can be used to verify that the FTP server has been properly configured. Run the following command to create the user, along with a home directory into which it can upload files.

sudo useradd -m ftpuser
 Assign a password to our new user:

sudo passwd ftpuser
 Now, enter the AdministratorPassword located to the left of these instructions. You will be prompted to confirm the change. Enter the password a second time.

 You’ve successfully created your test user. Next, create an FTP directory for the user:


sudo mkdir /home/ftpuser/ftp
 Change ownership of the directory and remove the permissions:

sudo chown nobody:nobody /home/ftpuser/ftp
sudo chmod a-w /home/ftpuser/ftp
 Now, create a subdirectory into which the user will upload files. Unlike the 

/home/ftpuser/ftp
 directory, make ftpuser the owner of this directory:

sudo mkdir /home/ftpuser/ftp/files
sudo chown ftpuser:ftpuser /home/ftpuser/ftp/files
 The newly created user needs to be added to the list of users permitted to access the vsftpd server. Use the following commands to create a list of authorized users, add our test user to the list, and then move the file to the /etc directory:

echo "ftpuser" > ~/vsftpd.chroot_list
sudo chown root:root ~/vsftpd.chroot_list
sudo mv ~/vsftpd.chroot_list /etc/vsftpd.chroot_list
 Now, restart vsftpd and then confirm that it is running:

sudo systemctl restart vsftpd
sudo systemctl status vsftpd
 The output should look similar to:


sh-4.2$ sudo systemctl status vsftpd
● vsftpd.service - Vsftpd ftp daemon
   Loaded: loaded (/usr/lib/systemd/system/vsftpd.service; disabled; vendor preset:disabled)
   Active: active (running) since Tue 2021-03-23 19:51:26 UTC; 23h ago
  Process: 31482 ExecStart=/usr/sbin/vsftpd /etc/vsftpd/vsftpd.conf (code=exited, status=0/SUCCESS)
 Main PID: 31484 (vsftpd)
   CGroup: /system.slice/vsftpd.service
           └─31484 /usr/sbin/vsftpd /etc/vsftpd/vsftpd.conf

Mar 23 19:51:26 ip-10-0-3-194.ec2.internal systemd[1]: Starting Vsftpd ftp daemon...
Mar 23 19:51:26 ip-10-0-3-194.ec2.internal systemd[1]: Started Vsftpd ftp daemon.
Hint: Some lines were ellipsized, use -l to show in full.
 Congratulations! You have successfully installed and configured vsftpd.

Task 3: Configure firewall rules
Despite the fact that the ftpHost is already protected by Security Groups, the Security Team has instructed you to configure an additional firewall at the operating system level.

In this task, you will run a script that installs firewalld and configures it to allow FTP traffic.

 Use the ls command to view the contents of the /home directory.

ls ~
The output should display two files:


sh-4.2$ ls
configureFirewall.sh  myvsftpd.conf
 The firewalld application uses zones to determine the trustworthiness of network connections. Since the FTP server is intended to be used by a large number of contractors and external consultants, you have been asked to configure access using public - or, untrusted - zones.

The configureFirewall.sh script automates this process for you. After installing firewalld, it creates two public zones. The first of which permits clients to register and authenticate with the FTP server over port 21 and the second permits data transfer on ports 40000-41000.

In the following snippet taken from the configureFirewall.sh script, note that the 

--zone=public
 flag is used to create these zones:


...
echo "Opening port 21 for FTP registration..."
sudo firewall-cmd --zone=public --permanent --add-port=21/tcp
echo "Opening ports 40000-41000 for data transfer..."
sudo firewall-cmd --zone=public --permanent --add-port=40000-41000/tcp
...
 Now run the script to install and configure firewalld.

cd ~ && sudo chmod +x configureFirewall.sh && sudo ./configureFirewall.sh
Press 1 to begin installing and configuring firewalld.
 Uh-oh! After opening ports 20 and 21, the script appears to have stopped running and you are unable to enter new commands. Something appears to have gone wrong and the ftpHost has become unresponsive.

Begin the troubleshooting process by confirming that the instance is running.

Close the browser tab you used to connect to ftpHost and return to the AWS Management Console.

From the breadcrumbs at the top of the screen, select the Instances link.

Select the checkbox next to ftpHost and open the the Details tab. Confirm that the Instance State is  Running

Now that you have confirmed that ftpHost is running, try establishing a new connection using EC2 Instance Connect.

With ftpHost still selected, choose the choose Connect button at the top of the screen.
 You are brought to the Connect to instance page.

Select the EC2 Instance Connect tab and attempt to connect to the ftpHost.
 EC2 Instance Connect opens in a new tab, but is unable to establish a new connection. An error message is displayed. Perhaps the firewall is blocking SSH connections. Try connecting to the instance using Session Manager.

 Session Manager manager is an interactive shell that allows you to connect to instances without needing to manage SSH keys or open inbound ports.

Close the browser tab that failed to connect using EC2 Instance Connect.

Return to the browser tab open to the Connect to instance page.

Open the Session Manager tab and choose Connect

 Session Manager is unable to establish a connection to the host. Depending on how much time has elapsed since the instance lost connectivity, you may find that the the Connect button at the bottom of the screen in unavailable.

Task 4: Allow access to EC2 Serial Console and connect to the instance
It appears that the firewall rules you added to the ftpHost inadvertently knocked the instance off of the network. Without network connectivity, you are unable to use EC2 Instance Connect, Session Manager, or an SSH client to access the shell. Fortunately, the EC2 Serial Console does not require an instance to have any networking capabilities. Using the serial console, you can interact with an instance as if your keyboard and monitor were directly attached to its serial port.

Start by determining whether or not your account allows access to the EC2 Serial Console.

From the breadcrumbs at the top of the screen, choose the EC2 link.
 You are returned to the EC2 Dashboard.

In the Account Attributes card on the right side of the screen, choose EC2 Serial Console.

Choose Manage.

Ensure that the Allow checkbox has been selected. If it hasn’t, select the checkbox and choose Update.

 EC2 Serial Console access is enabled across your entire account. Alternatively, if you preferred to provide more granular access to the serial console, you could use a combination of service control policies (SCP) and IAM policies to scope access to meet your requirements. For a detailed explanation of how EC2 Serial Console access can be configured, please see the User Guide.

Before connecting to an instance using EC2 Serial Console, an IAM user must be granted explicit permission. Fortunately, since you are a network administrator, you have already been given these permissions.

Below is an example of a policy document that could be used to grant a user access to EC2 Serial Console. Note that the document includes the 

ec2-instance-connect:SendSerialConsoleSSHPublicKey
 action. This action grants an IAM user permission to push the public key to the serial console service, which starts a serial console session.


{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowSerialConsoleAccess",
            "Effect": "Allow",
            "Action": [
                "ec2-instance-connect:SendSerialConsoleSSHPublicKey"
            ],
            "Resource": "arn:aws:ec2:region:account-id:instance/i-0598c7d356eba48d7"
        }
    ]
}
From the breadcrumbs at the top of the screen, choose the EC2 link to return to the dashboard.

Choose Instances (running).

Select the checkbox next to ftpHost and choose Connect..

Open the EC2 serial console tab.

Choose Connect..

 A new tab opens displaying an terminal session.

Place your cursor in the window and press Enter.
A login prompt appears in the terminal window.

At the login prompt, type root.

In the password field, enter the value of AdministratorPassword located to the left of these instructions.

 Congratulations! You have successfully connected the FTP Host using the EC2 Serial Console.

Task 5: Troubleshoot firewalld
In this task, you will troubleshoot the firewalld to get the ftpHost back onto the network.

 Confirm that firewalld is running. Enter:

systemctl status firewalld.service
 It appears that the firewalld service is running. Let’s see if we can find anything unusual in the logs. Enter the following command to view them:

less /var/log/firewalld
The logs do not contain any useful information, so let’s look at the rules you applied. Perhaps one of the them knocked the machine offline.

 Type q to close less and then enter the following command to view the services and ports that are permitted:


firewall-cmd --list-ports
 That’s odd. The command output does not display any services or ports. Your firewall should be configured to allow TCP on ports 21 and 40000-41000, but it appears that it’s blocking all traffic.

 It is possible that something triggered firewalld to enter panic mode. Panic mode is an emergency state that terminates all network connections and prevents new connections from being established.

 Enter the following command to see if panic mode is enabled:

firewall-cmd --query-panic
 Review the output:

root@ip-172-31-13-0:~# firewall-cmd --query-panic
yes
The firewall has entered panic mode. This explains why you have been unable to connect to the instance.

 Enter the following command to turn off panic mode:

firewall-cmd --panic-off
 Restart the firewall:

systemctl restart firewalld
Press 

ENTER
 to retun to the command prompt.

 Verify that firewalld is functioning normally:


systemctl status firewalld
 The output should look similar to:


● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: active (running) since Thu 2022-09-22 14:40:45 UTC; 18s ago
     Docs: man:firewalld(1)
 Main PID: 13916 (firewalld)
   CGroup: /system.slice/firewalld.service
           └─13916 /usr/bin/python -Es /usr/sbin/firewalld --nofork --nopid

Sep 22 14:40:44 ip-10-0-1-251.ap-northeast-1.compute.internal systemd[1]: Sta...
Sep 22 14:40:45 ip-10-0-1-251.ap-northeast-1.compute.internal systemd[1]: Sta...
Hint: Some lines were ellipsized, use -l to show in full.
Before closing the Serial Console connection, you should restart the SSM Agent. This will ensure that other users are able to access the instance using Session Manager Enter the following command:

systemctl restart amazon-ssm-agent
 The SSM Agent runs on EC2 instances and uses Systems Manager documents to enable Session Manager.

To confirm that the instance has regained network connectivity, close the current browser tab and return to the Connect to instance page within the AWS Management Console.

Choose the EC2 Instance Connect tab.

 If the Connect button appears greyed-out, wait one minute and then refresh the page.

Choose Connect.
 Well done! EC2 Instance Connect successfully connected to the ftpHost. The instance is back online and you’ve restarted the firewall. Now, let’s confirm that vsftpd was configured correctly.

Task 6: Upload a file to FTP Host
In this final task, you will use a Windows instance to confirm that users are able to successfully upload files to the FTP server.

Close the browser tab containing your EC2 instance connect session.
 You are returned to the Connect to instance page.

From the breadcrumbs at the top of the page, choose the Instances link.

At the top of the Instances panel select the checkbox next to ftpClient.

Choose Connect..

Open the RDP Client tab and choose Download remote desktop file..

Use an RDP client on your local machine to open the remote desktop file and connect to the ftpClient.

 You may be presented with a message similar to the one below:

You are connecting to the RDP host <FTP Client IP Address>. The certificate couldn’t be verified back to a root certificate. Your connection may not be secure. Do you want to continue?

Choose Continue.

Copy the AdministratorPassword displayed to the left of the lab instructions. When prompted, enter this password to connect to the ftpClient.

Double-click on the Filezilla desktop shortcut.

 Filezilla Client is an open source FTP client. You will use it to upload a file to the ftpHost.

Choose OK to close the popup window.
 You may be presented with a second popup window suggesting that you update Filezilla. For the purposes of this lab, you do not need to upgrade. Choose Close.

Paste the FtpHostPrivateIp displayed to the left of the lab instructions into the Host field at the top of the screen.

Enter 

ftpuser
 in the Username field.

Enter the value of AdministratorPassword located to the left of these instructions in the Password field.

Click the Quickconnect. button.

A popup window appears asking if you would like Filezilla to save passwords. Choose Do not save passwords and then click the OK..

A second popup window appears alerting you that the FTP Server does not support FTP over TLS. Choose OK.

 Filezilla establishes a connection with the the ftpHost.

Use the file explorer on the left side of the Filezilla client to navigate to C:\Users\Administrator\Documents.

 A log file named sample.log has been saved to the Documents folder. Right-click on the sample.log file and select Upload.

Confirm that the sample.log file now appears in the window on the right side of the screen.

 Congratulations! The file successfully uploaded to the ftpHost.

Conclusion
 Congratulations! You have successfully:

Configured an FTP server using vsftpd and firewalld.
Enabled Serial Console at the account level.
Connected to an EC2 instance using Serial Console.
Used Remote Desktop (RDP) to connect to an Amazon EC2 instance running Windows Server