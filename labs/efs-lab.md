Amazon Elastic File System (EFS) Performance

Lab overview
When considering Amazon Elastic File System (EFS), you should understand the performance characteristics of the file system and how Amazon EC2 instance types, I/O size, and parallelism can affect the performance. In this lab, you review scenarios that use various file creation and copy tools to showcase the way that different Amazon Elastic Cloud Compute (EC2) instance types, I/O, and numbers of threads accessing Amazon EFS can have an impact on performance. You also use an Amazon CloudWatch dashboard with custom metrics created using metric math to monitor the activities with common storage metrics.

TOPICS COVERED
The goal of this lab is to show how:

EC2 instance types affect EFS performance.
I/O size (block size) and sync frequency affect EFS performance.
Increasing the number of threads accessing EFS can improve performance.
Different file transfer tools affect performance when accessing an EFS file system.
Scale-out data transfer using multiple EC2 instances can improve EFS performance.
TECHNICAL KNOWLEDGE PREREQUISITES
To successfully complete this lab, you should be familiar with basic navigation of the AWS Management Console, storage and networking concepts, and be comfortable using Linux commands.

Take that time to review the details of the environment. It contains the following resources:

An EFS file system configured for 200 MB provisioned throughput.
Three EC2 instances for the performance tasks.
Three EC2 instances for the scale-out tasks.
An architecture diagram of the lab environment that depicts six Amazon EC2 instances in a public subnet, inside of a VPC, inside of the AWS Cloud. An Amazon Elastic File System is shown inside of the VPC, but outside of the public subnet. All six EC2 instances are connected to the Amazon EFS file system.

The EFS file system is mounted to each EC2 instance. The instances have a 20 GB gp2 EBS data volume mounted with 5GB of test data generated on that volume.

The following open source applications are installed on each instance:

nload: a console application that monitors network traffic and bandwidth usage in real time.
smallfile: used to generate test data - Developer: Ben England.
GNU Parallel: used to parallelize single-threaded commands - O. Tange (2011): GNU Parallel - The Command-Line Power Tool, The USENIX Magazine, February 2011:42-47.
fpart: sorts file trees and packs them into partitions - Author Ganaël Laplanche.
fpsync: wraps fpart + rsync together as a multi-threaded transfer utility; included in the tools/ directory of fpart.
 Note: Amazon Web Services does NOT endorse specific third party applications. These software packages are used for demonstration purposes only. Follow all expressed or implied license agreements associated with these third party software products.

Task 1: How the number of threads used to write data affects Amazon EFS performance
In this task, you use the touch command to generate zero-byte files on the EFS file system. You create multiple files using single and multiple threads and compare the performance difference between each method.

At the top of the AWS Management Console, in the search bar, search for and choose EC2.

In the navigation pane at the left of the page, choose Instances.

Select Performance Instance 3 and then, at the top-right of the page, choose Connect.

On the Connect to instance page, choose the Session Manager tab, and then choose Connect.

 Expected output: A new web browser tab opens with a console connection to the instance. A set of commands are run automatically when you connect to the instance that change to the user’s home directory and display the path of the working directory, similar to this:


cd $HOME; pwd
sh-4.2$ cd $HOME; pwd
/home/ec2-user
sh-4.2$


 In this lab, you use AWS Systems Manager Session Manager, referred to as SSM, to connect to the Amazon EC2 instances.

 Enter the following command to set an environment variable named directory that contains the instance ID of this instance:

directory=$(wget -q -O - http://169.254.169.254/latest/meta-data/instance-id)
 Note: The Instance ID is used to identify a unique directory on the EFS file share for each instance in the lab.

 Note: On a Windows-based computer, you might need to use Ctrl + Shift + V or open the context menu (right-click) to paste text into a Session Manager console window.

Use a single thread to create files
 Enter the following command to use touch with a single thread to generate 1024 zero-byte files in the /mnt/efs/01/touch directory:

time for i in {1..1024}; do touch /mnt/efs/touch/${directory}/test-1.3-$i; done;
 Expected output: The output displays the time taken to complete the command, similar to this:


real    0m9.856s
user    0m0.653s
sys     0m0.216s
Open the text editor of your choice and record the value for real time. We will use the values recorded in your text editor to compare the returned results.

Return to your browser tab with the connection to Performance Instance 3.

Use multiple threads to create files
 Enter the following command to use touch with multiple threads to generate 1024 zero-byte files in the /mnt/efs/01/touch directory.

time seq 1 1024 | parallel --will-cite -j 128 touch /mnt/efs/touch/${directory}/test-1.4-{}
When the command completes, record the real time in your text editor.
Use multiple threads to create files in multiple directories
 Enter the following command to create 32 directories, labeled 1 through 32, in the /mnt/efs/01/touch directory.

mkdir -p /mnt/efs/touch/${directory}/{1..32}
 Enter the following command to use touch with multiple threads to generate 1024 zero-byte files in the numbered directories you created in the previous task:

time seq 1 32 | parallel --will-cite -j 32 touch /mnt/efs/touch/${directory}/{}/test-1.5-{1..32}
 Note: The command creates 32 zero-byte files in each of the 32 directories for a total of 1024 files.

When the command completes, record the real time in your text editor.

Close the SSM session and examine the data you collected.

 Consider: Notice that the time it took to create files using multiple threads is significantly less than using a single thread and that using multiple threads with multiple directories takes even less time. How you choose to write files to an EFS file system can have a dramatic impact on performance.

Your results should be similar to the results shown here:

Instance name	EC2 Instance type	Threads	File count	Duration (in seconds)	Files per second
Performance Instance 3	m5.xlarge	single threaded	1024	8.794	116.44
Performance Instance 3	m5.xlarge	multi threaded	1024	4.510	227.05
Performance Instance 3	m5.xlarge	multi threaded and different directories	1024	0.907	1129.00
 Congratulations! You have successfully demonstrated how the number of threads and directories used when writing to an EFS file share can impact performance.

Task 2: How the network performance of EC2 instance types affect Amazon EFS performance
In this task, you write 10GB of data to the EFS file system from three different EC2 instance types—t3.micro, m4.large, and m5.xlarge—and note the difference in performance between each instance.

The first instance you connect to, Performance Instance 1, is a t3.micro instance running Amazon Linux 2.

Return to your browser tab with the AWS Management Console.

At the top of the AWS Management Console, in the search bar, search for and choose EC2.

In the navigation pane at the left of the page, choose Instances.

Select Performance Instance 1 and then, at the top-right of the page, choose Connect.

On the Connect to instance page, choose the Session Manger tab, and then choose Connect.

 Expected output: A new browser tab opens with a console connection to the instance. A set of commands are run automatically when you connect to the instance that change to the user’s home directory and display the path of the working directory, similar to this:


cd $HOME; pwd
sh-4.2$ cd $HOME; pwd
/home/ec2-user
sh-4.2$
For this task, you connect to the same EC2 instance using two separate SSM sessions so that you can monitor the network traffic using nload and view the results of the commands you enter at the same time.

Copy the URL of the open SSM connection page you are currently on, and then paste that link into a new browser window. You should now have two SSM sessions open to Performance Instance 1.

 In the first SSM session window, enter the following command to launch nload to monitor network throughput:


nload -u M
 Expected output: The nload utility opens and displays the current network statistics for incoming and outgoing traffic, similar to this:


Device eth0 [10.0.2.162] (1/2):
=====================================================================
Incoming:





                                                    Curr: 0.00 MByte/s
                                                    Avg: 0.00 MByte/s
                                                    Min: 0.00 MByte/s
                                                    Max: 0.01 MByte/s
                                                    Ttl: 208.99 MByte
Outgoing:





                                                    Curr: 0.00 MByte/s
                                                    Avg: 0.00 MByte/s
                                                    Min: 0.00 MByte/s
                                                    Max: 0.01 MByte/s
                                                    Ttl: 27.44 MByte
 In the second SSM session window, enter the following command to use the dd utility to write 10GB of data to the EFS file system:

time dd if=/dev/zero of=/mnt/efs/dd/10G-dd-$(date +%Y%m%d%H%M%S.%3N) bs=1M count=10000 conv=fsync
The following list explains the various options you just used with the dd command:

time tracks how long the command takes to run to completion.
if= defines the input file to read from.
of= defines the file to write to.
bs= defines the number of bytes to read and write at a time.
count= specifies the the number of blocks to write.
conv=fsync specifies that metedata should be written as well.
The end result of the command is that 10,000 1MB blocks of data are written to the EFS file share for a total of 10GB.
 For more information about the dd utility, refer to dd Linux manual page in the Additional resources section.

Monitor the SSM session with nmap running and observe the outgoing throughput.
Wait for the 10GB of data to be written, which can take approximately 1 minute. You can see the amount of data that has been written in the Ttl line in the first SSM window where nmap is running. The output of the command in the second window also shows the total time required to write the data.

Record the real time in seconds, and then record it in your text editor.

Close the two SSM sessions you have open to Performance Instance 1.

In addition to the nmap utility, you can also view the performance metrics of the EFS file system with a custom Amazon CloudWatch dashboard.

Return to your browser tab with the AWS Management Console.

At the top of the AWS Management Console, in the search bar, search for and choose 

CloudWatch.

In the navigation pane at the left of the page, choose Dashboards.

Choose the link for the dashboard name that starts with EFS-performance-dashboard. Examine the various metrics provided.

At the top-right of the page, choose 1h to change the time frame to show the last one hour.

At the top-right of the page, choose the  drop-down next to the refresh button, and then:

Select Auto refresh.
For Refresh interval, select 10 seconds.
Repeat the previous steps in this task to perform the same test on Performance Instance 2, an m4.large instance, and Performance Instance 3, an m5.large instance.

Record the results in your text editor and monitor the CloudWatch dashboard.

After you have completed the tests on all three instance types, close all SSM sessions.

Your results should be similar to the following:

Instance name	EC2 Instance Type	Data Size	Duration (in seconds)	Average Throughput (in MB/s)
Performance Instance 1	t3.micro	10 GB	50.936	402.073
Performance Instance 2	m4.large	10 GB	185.795	110.229
Performance Instance 3	m5.large	10 GB	50.988	401.663
 Consider: What do you notice about each instance type? Did anything in particular about the t3.micro instance stand out? How does the time to complete writing the data and the network throughput compare between each one?

 All EC2 instance types have different network performance characteristics, so each can drive different levels of throughput to Amazon EFS. While the t3.micro instance initially appears to have better network performance when compared to an m4.large instance, its high network throughput is short lived as a result of the burst characteristics of t3 instances. Review the EC2 instance type characteristics for the t3.micro, m4.large and m5.xlarge instances here. In particular, look at the network performance statistics for the different instance types.

 Congratulations! You have successfully demonstrated how the network performance characteristics of an EC2 instance can impact Amazon EFS file system performance.

Task 3: How I/O size and sync frequency affect throughput to Amazon EFS
Different I/O sizes (block sizes) and sync frequencies (the rate data is persisted to disk) have profound impacts on performance when writing to EFS. In this task, you write data to the EFS file system using different block sizes and sync frequencies and observe how each affects throughput to Amazon EFS.

Next, you connect to Performance Instance 3, an m5.large instance.

Return to your browser tab with the AWS Management Console.

At the top of the AWS Management Console, in the search bar, search for and choose 

EC2.

In the navigation pane at the left of the page, choose Instances.

Select Performance Instance 3 and then, at the top-right of the page, choose Connect.

On the Connect to instance page, choose the Session Manger tab, and then choose Connect.

 Expected output: A new browser tab opens with a console connection to the instance. A set of commands are run automatically when you connect to the instance that change to the user’s home directory and display the path of the working directory, similar to this:


cd HOME; pwd
sh-4.2$ cd HOME; pwd
/home/ec2-user
sh-4.2$
Create files with a 1 MB block size and sync after each file
 Enter the following command to use dd to create 2 GB of files on the EFS file system using a 1 MB block size and issue a sync once after each file to verify the file is written to disk:

time dd if=/dev/zero of=/mnt/efs/dd/2G-dd-$(date +%Y%m%d%H%M%S.%3N) bs=1M count=2048 status=progress conv=fsync
Convert the real time to seconds, and then record it in your text editor.
Create files with a 16 MB block size and sync after each file
 Enter the following command to use dd to create 2 GB of files on the EFS file system using a 16 MB block size and issue a sync once after each file to verify the file is written to disk:

time dd if=/dev/zero of=/mnt/efs/dd/2G-dd-$(date +%Y%m%d%H%M%S.%3N) bs=16M count=128 status=progress conv=fsync
Convert the real time to seconds, and then record it in your text editor.
Create files with a 1 MB block size and sync after each block
 Enter the following command to use dd to create 2 GB of files on the EFS file system using a 1 MB block size and issue a sync after each block to verify each block is written to disk:

time dd if=/dev/zero of=/mnt/efs/dd/2G-dd-$(date +%Y%m%d%H%M%S.%3N) bs=1M count=2048 status=progress oflag=sync
Convert the real time to seconds, and then record it in your text editor.
Create files with a 16 MB block size and sync after each block
 Enter the following command to use dd to create 2 GB of files on the EFS file system using a 16 MB block size and issues a sync after each block to verify each block is written to disk.

time dd if=/dev/zero of=/mnt/efs/dd/2G-dd-$(date +%Y%m%d%H%M%S.%3N) bs=16M count=128 status=progress oflag=sync
Convert the real time to seconds, and then record it in your text editor.

Remain connected to the instance for the next task.

Your results should be similar to the following:

Instance name	EC2 Instance type	Operation	Data size	Block size	Sync frequency	Duration (in seconds)	Throughput (in MB/s)
Performance Instance 3	m5.large	Create	10 GB	1 MB	After each file	10.842	188.8
Performance Instance 3	m5.large	Create	10 GB	16 MB	After each file	10.875	188
Performance Instance 3	m5.large	Create	10 GB	1 MB	After each block	61.325	33.3
Performance Instance 3	m5.large	Create	10 GB	16 MB	After each block	24.692	82.9
 Consider: What do the results show?

Notice that the throughput drops dramatically when the sync method is changed from per-file to per-block. Throughput drops even further when you sync per-block, and the block size is reduced from 16 MB to 1 MB. However, when syncing per-file the block size has little impact on throughput.

 Congratulations! You have successfully demonstrated how block size and sync frequency affect EFS performance.

Task 4: How multi-threaded access improves throughput and IOPS
In this task, you use the sync command to show how increasing the number of threads accessing an Amazon EFS file system significantly improves performance.

 Sync writes to disk any data buffered in memory. This can include (but is not limited to) modified superblocks, modified inodes, and delayed reads and writes. This must be implemented by the Linux kernel. The sync program does nothing but exercise the sync(2) system call.

The kernel keeps data in memory to avoid doing disk reads and writes, which can be relatively slow. Doing so improves performance, but if the computer crashes data may be lost or the file system corrupted. Sync ensures that everything in memory is written to disk.

If you are not already connected to Performance Instance 3, use the steps from the previous task to connect to it.

 Enter the following command to use dd to write 2 GB of data to Amazon EFS using a 1 MB block size and 4 threads and issue a sync after each block to ensure everything is written to disk:


time seq 0 3 | parallel --will-cite -j 4 dd if=/dev/zero of=/mnt/efs/dd/2G-dd-$(date +%Y%m%d%H%M%S.%3N)-{} bs=1M count=512 oflag=sync
Convert the real time to seconds, and then record it in your text editor.

 Enter the following command to use dd to write 2 GB of data to Amazon EFS using a 1 MB block size and 16 threads and issue a sync after each block to ensure everything is written to disk:


time seq 0 15 | parallel --will-cite -j 16 dd if=/dev/zero of=/mnt/efs/dd/2G-dd-$(date +%Y%m%d%H%M%S.%3N)-{} bs=1M count=128 oflag=sync
Convert the real time to seconds, and then record it in your text editor.

Remain connected to the instance for the next task.

Your results should be similar to the results shown here.

Instance name	EC2 Instance type	Operation	Data Size	Block Size	Threads	Sync Frequency	Duration (in seconds)	Average Throughput (in MB/s)
Performance Instance 3	m5.large	Create	2 GB	1 MB	4	After each block	16.929	120
Performance Instance 3	m5.large	Create	2 GB	1 MB	16	After each block	10.406	196
 Consider: The distributed data storage design of EFS means that multi-threaded applications can drive substantial levels of aggregate throughput and IOPS. If you parallelize your writes to EFS by increasing the number of threads, you can increase the overall throughput and IOPS to EFS.

Task 5: Compare file transfer tools
In this this task, you explore the way that different file transfer tools affect performance when accessing an Amazon EFS file system.

If you are not already connected to Performance Instance 3, use the steps from the previous task to connect to it.

 Enter the following command to view the number of sample files used throughout this task:


find /ebs/data-1m/. -type f | wc -l
 Expected output: The output should show a total of 5000 files.

 Enter the following command to view the total size of the sample files used throughout this task:

du -csh /ebs/data-1m/
 Expected output: The output should show a total size of 4.9 GB.

 Enter the following command to monitor the network throughput of the instance:

nload -u M
For this task, you connect to the same EC2 instance using two separate SSM sessions so that you can monitor the network traffic using nload and view the results of the commands you enter at the same time.

Copy the URL of the open SSM connection page you are currently on, and then paste that link into a new browser window. You should now have two SSM sessions open to Performance Instance 3.

 In the second SSM session, enter the following command to create an environment variable named instance_id to use in upcoming commands:


instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
Use the rsync utility to copy files
 Enter the following commands to drop caches and use rsync to transfer 5,000 files that are approximately 1 MB each, totaling 5 GB, from instance’s local EBS volume to the EFS file system:

sudo su
sync && echo 3 > /proc/sys/vm/drop_caches
exit
time rsync -r /ebs/data-1m/ /mnt/efs/rsync/${instance_id}
 Note: The command can take approximately eight minutes to complete.

 Linux kernels 2.6.16 and newer provide a mechanism to have the kernel drop the page cache and/or inode and dentry caches on command, which can help free up a lot of memory. This is a non-destructive operation and only frees things that are completely unused. Dirty objects continue to be in use until written out to disk and are not able to be freed by this mechanism. Clearing cache frees RAM, but it causes the kernel to look for files on the disk rather than in the cache. You can drop caches like this as a method of benchmarking disk performance.

Monitor the network throughput in the SSH session where nload is running.

When the command completes, convert the real time to seconds, and then, record it your text editor.
Use the cp utility to copy files
 Enter the following commands to drop caches and use cp to transfer 5,000 files of approximately 1 MB each, totaling 5 GB, from the instance’s local EBS volume to the EFS file system:

sudo su
sync && echo 3 > /proc/sys/vm/drop_caches
exit
time cp -r /ebs/data-1m/* /mnt/efs/cp/${instance_id}
Monitor the network throughput in the SSH session where nload is running.

When the command completes, convert the real time to seconds, and then record it in your text editor.

 Enter the following command to set the threads environment variable to 4 threads per vCPU. The variable is used in upcoming steps. As the m5.xlarge instance has 8 vCPU, the command enables the use of 32 threads, which is the number of vCPU x 4).


threads=$(($(nproc --all) * 4))
Use the fpsync utility to copy files
 Enter the following commands to drop caches and use fpsync to transfer 5,000 files approximately 1 MB each, totaling 5 GB, from the instance’s EBS volume to the EFS file system:

sudo su
sync && echo 3 > /proc/sys/vm/drop_caches
exit
time /usr/local/bin/fpsync -n ${threads} -v /ebs/data-1m/ /mnt/efs/fpsync/${instance_id}
Monitor the network throughput in the SSH session where nload is running.

When the command completes, convert the real time to seconds, and then record it in your text editor.
Use the cp and GNU Parallel utilities to copy files
 Enter the following commands to drop caches and use cp and GNU Parallel to transfer 5,000 files approximately 1 MB each, totaling 5 GB, from the instance’s EBS volume to the EFS file system:

sudo su
sync && echo 3 > /proc/sys/vm/drop_caches
exit
time find /ebs/data-1m/. -type f | parallel --will-cite -j ${threads} cp {} /mnt/efs/parallelcp
Monitor the network throughput in the SSH session where nload is running.

When the command completes, convert the real time to seconds, and then record it in your text editor.
Use the fpart, cpio, and GNU Parallel utilities to copy files
 Enter the following commands to drop caches and use fpart, cpio, and GNU Parallel to transfer 5,000 files approximately 1 MB each, totaling 5 GB, from the instance’s EBS volume to the EFS file system:

sudo su
sync && echo 3 > /proc/sys/vm/drop_caches
exit
cd /ebs/smallfile
time /usr/local/bin/fpart -z -n 1 -o /home/ec2-user/fpart-files-to-transfer .
head /home/ec2-user/fpart-files-to-transfer.0
time parallel --will-cite -j ${threads} --pipepart --round-robin --delay .1 --block 1M -a /home/ec2-user/fpart-files-to-transfer.0 sudo "cpio -dpmL /mnt/efs/parallelcpio/${instance_id}"
Monitor the network throughput in the SSH session where nload is running.

When the command completes, convert the real time to seconds, and then record it in your text editor.

Close the SSM connection to Performance Instance 3.

Your results should be similar to the following:

Instance name	EC2 Instance type	File transfer tool	File count	File size	Total size	Threads	Duration (in seconds)	Throughput (in MB/s)
Performance Instance 3	m5.large	rsync	5000	1 MB	5 GB	1	247.142	20
Performance Instance 3	m5.large	cp	5000	1 MB	5 GB	1	173.746	29
Performance Instance 3	m5.large	fpsync	5000	1 MB	5 GB	32	114.255	44.81
Performance Instance 3	m5.large	cp + GNU Parallel	5000	1 MB	5 GB	32	44.928	113.96
Performance Instance 3	m5.large	fpart + cpio + GNU Parallel	5000	1 MB	5 GB	32	41.296	123.98
As demonstrated here, not all file transfer utilities are created equal. Amazon EFS file systems are distributed across an unconstrained number of storage servers and this distributed data storage design means that multithreaded applications like fpsync, mcp, and GNU parallel can drive substantial levels of throughput and IOPS to EFS when compared to single-threaded applications.

 You can also use AWS DataSync to transfer data to Amazon EFS. For more information, refer to AWS DataSync in the Additional resources section.

 Congratulations! You have successfully demonstrated how the utilities you use to copy data to an Amazon EFS file share can affect performance.

Task 6: Using a scale-out architecture with Amazon EFS
In this task, you examine the distributed data storage design of Amazon EFS and how to best leverage this design by taking advantage of scale-out architectures.

Three m4.xlarge EC2 instances have been deployed for use in this task.

Return to your browser tab with the AWS Management Console.

At the top of the AWS Management Console, in the search bar, search for and choose 

Systems Manager.

In the navigation pane at the left of the page, under Node Management, choose Run Command.

On the AWS Systems Manager Run Command page, choose Run a Command.

On the Run a command page, in the Command document section, search for 

AWS-RunShellScript

Select the AWS-RunShellScript document.

 Caution: Do NOT choose the AWS-RunShellScript link. Only select the radio button to the left of it.

Copy the following path to the script file to run on each instance and paste it into the Command parameters section.
Replace EFS_FILE_SYSTEM_ID with the value of the EfsFileSystemId shown to the left of these instructions.

/home/ec2-user/scale-out-get-lidar-data.sh EFS_FILE_SYSTEM_ID
For example:


/home/ec2-user/scale-out-get-lidar-data.sh fs-d5cf49cc
In the Targets section, select Choose instances manually.

In the Instances section, select all three instances with the name Scale-out Instance. Doing so sends the command to all of the selected instances at the same time.

In the Output options section, clear Enable an S3 bucket.

Leave all other options at their default values.

At the bottom of the page, choose Run.

A green banner appears at the top of the screen stating the command was successfully sent, and the status of the command run is displayed for each instance.

At the top of the AWS Management Console, in the search bar, search for and choose 

CloudWatch.

In the navigation pane at the left, choose Dashboards.

Choose the link for the dashboard name that starts with EFS-performance-dashboard.

At the top-right of the page, choose 1h to change the time frame to show the last one hour.

At the top-right of the page, choose the  drop-down next to the refresh button, and then:

Select Auto refresh.
For Refresh interval, select 10 seconds.
Monitor the the Throughput and Total IOPS widgets pn CloudWatch dashboard for approximately 10-15 minutes.
 Note: The command you ran downloads a large amount data so that the copy process will last through the end of the lab. It is intended to generate enough data points to observe on the graphs. You do not have to wait until the copy process finishes, which can take approximately one hour.

While observing the graphs:
Hover your mouse over the various data points. What is the throughput?
Remember that the EFS file share in this environment is configured as 200 MB/s provisioned, so that is the maximum throughput possible.
How does the throughput compare to what you observed in the previous exercises?
Choose the image below to open a new tab with a video demonstration of the results of the same scale-out steps performed in this task, but using an EFS file system with a permitted throughput of greater than 3 GB/s
EFS Scale Out Demo Video

Conclusion
The distributed data storage design of Amazon EFS enables high levels of availability, durability, and scalability. This distributed architecture results in a small latency overhead for each file operation. Due to this per-operation latency, overall throughput generally increases as the average I/O size increases, because the overhead is amortized over a larger amount of data. Amazon EFS supports highly parallelized workloads (for example, using concurrent operations from multiple threads and multiple Amazon EC2 instances), which enables high levels of aggregate throughput and operations per second.

 Congratulations! You now have successfully:

Demonstrated how EC2 instance types affect EFS performance.
Demonstrated the effect of I/O size (block size) and sync frequency on EFS performance.
Shown that increasing the number of threads writing data to EFS also increases throughput to EFS.
Discovered that the file transfer tool used to copy data to EFS has an impact on performance.
Shown how scale-out data transfer using multiple EC2 instances improves EFS performance.