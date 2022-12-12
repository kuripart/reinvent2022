Benchmarking Amazon EBS Volumes

Lab overview
Benchmarking is the process of measuring the performance of your application infrastructure and exploring the factors that influence it.

Here we look at some of the factors that can influence Amazon Elastic Block Store (Amazon EBS) performance. We will focus on Amazon EBS volume type, the application I/O profile, and the host-side logical volume configuration.

In this lab, you will establish initial Amazon EBS volume performance baseline expectations in terms of I/O operations per second (IOPS) and throughput (MiB/s). You will use Flexible IO Tester (FIO) to simulate application workloads. And you will use a logical volume performance optimization technique known disk striping (RAID 0). You will also learn how to monitor your storage volume performance with Amazon CloudWatch.

The architecture diagram of the lab environment, which shows an Amazon VPC with a single public subnet, one EC2 Instance (t3.micro), root device volume (gp3), and six secondary volumes (two st1 volumes labeled Logs1 & Logs2 and 4 gp3 volumes labeled Data1-4).

Amazon Elastic Block Store (Amazon EBS) provides block level storage volumes for use with Amazon Elastic Compute Cloud (Amazon EC2) instances. EBS volumes behave like raw, unformatted block devices. You can mount these volumes as devices on your instances. EBS volumes that are attached to an instance are exposed as storage volumes that persist independently from the life of the instance. You can create a file system on top of these volumes, or use them in any way you would use a block device (such as a hard drive). You can dynamically change the configuration of a volume attached to an instance.

Amazon EBS should be used for data that must be quickly accessible and requires long-term persistence. EBS volumes are particularly well-suited for use as the primary storage for file systems, databases, or for any applications that require fine granular updates and access to raw, unformatted, block-level storage. Amazon EBS is well suited to both database-style applications that rely on random reads and writes, and for throughput-intensive applications that perform long, continuous reads and writes.

Amazon CloudWatch monitors Amazon Web Services (AWS) resources and the applications you run on AWS in real time. You can use CloudWatch to collect and track metrics, which are variables you can measure for your resources and applications.

You can create alarms that watch metrics and send notifications or automatically make changes to the resources you are monitoring when a threshold is breached. For example, you can monitor the CPU usage and disk reads and writes of your Amazon EC2 instances and then use this data to determine whether you should launch additional instances to handle increased load. You can also use this data to stop under-used instances to save money.

With CloudWatch, you gain system-wide visibility into resource utilization, application performance, and operational health.


TOPICS COVERED
By the end of this lab, you will be able to:

Test the performance of different Amazon EBS volumes using FIO (Flexible IO Tester).
Use CloudWatch to monitor the performance of different EBS volume types.
Use disk striping to optimize the performance of your Amazon EBS volumes.
Evaluate the volume types most suitable for your application workloads.
TECHNICAL KNOWLEDGE PREREQUISITES
This lab requires:

SCENARIO
Your company is planning on deploying a new application to Amazon EC2 while using Amazon EBS volumes as the primary high availability block storage option. Tagging will be used to identify the primary type of data the different volumes will store. The volumes used to store application log files will be tagged with “log”. Volumes used for application data files will be tagged with “data”.

You have been asked to ensure this infrastructure will meet the throughput and IOPS requirements of your application. To acheive this you will need to establish perfomance benchmarks for the different EBS volumes and establish IOPS requirements. You will use FIO (Flexible IO Tester) to establish these benchmarks and requirements.


Task 1: Explore your environment
In this task, you’ll review the lab environment to become familiar with the services and components used throughout the lab.

This lab uses an Amazon EC2 instance that resides in a public subnet with restricted access, an Amazon EBS-backed root volume, two secondary st1 EBS volumes and four secondary gp3 EBS volumes.

First, examine the EC2 instance and its attached devices.

In the AWS management console, in the unified search bar, type in EC2 and select the EC2 service from the list of displayed options.

From the EC2 Dashboard select Instances (running) from the Resources card on the right.

Under Instances, choose the Instance ID with the name Lab-Instance.

In the Instance summary pane for Lab-Instance, scroll down and choose the Storage tab.

The Storage tab of an EC2 instance reveals the list of attached block devices. Here you can scroll down and review the properties, like Volume ID, Device name, Volume size and Attachment Status, of the volumes attached to your Lab-Instance.

Next, you will examine the details of the individual block devices in your account.

In the left navigation pane of EC2 console, scroll down to the Elastic Block Store section and choose the Volumes option.
Here you see a list of all the EBS volumes within your account. The details in each of the columns give an overview of the different volumes and their attributes like Name, Volume ID, Size, Volume Type, IOPS and Throughput.

 In this lab, you work with EBS volumes named Lab-Volume-XXX where XXX can be either Boot, Data or Logs.

Select the checkbox against the first volume name listed Lab-Volume-XXX. Below the account Volumes list, you will see the details of the selected volume, similar to those listed below, in the Details tab.
Size: The size of the volume, in GiBs
Type: The storage class of the EBS volume.
Throughput: The throughput that the volume supports, in MiB/s.
IOPS: The number of I/O operations per second (IOPS). For gp3, io1, and io2 volumes, this represents the number of IOPS that are provisioned for the volume. For gp2 volumes, this represents the baseline performance of the volume.
Select the Status checks tab, below the Volume ID.
Volume status checks enable you to better understand, track, and manage potential inconsistencies in the data on an Amazon EBS volume.

Confirm that your volume’s status is Okay and that I/O is enabled.

Select the Monitoring tab.
Here you will see an number of graphs concerning the metrics that the Amazon CloudWatch service is collecting on your EBS volumes.

After running our initial performance benchmarks we will return to this tab to review in more detail.

Select the Tags tab.
Here you will see a list of the tags associated with the EBS volume displayed. Authorized users can add additional tags to your account’s volumes through the console here. Tags consist of associated Key/Value pairs. Associating tags to your volumes allows for easier automation of tasks such as the creation of snapshots.

Now that you know how to access your EBS volume data at the account level in the AWS console, we will move to the EC2 instance command line.

Task 2: Connect to the EC2 Instance and Install FIO
To start benchmarking your EBS volumes, you need to connect to their attached EC2 instance. For this lab, you use Session Manager to connect to your Lab-Instance. Session Manager provides secure and auditable instance management without the need to open inbound ports, maintain bastion hosts, or manage SSH keys.

In the left navigation pane of the EC2 console, under Instances section, choose Instances.

Select the checkbox next to Lab-Instance.

In the top right corner of the Instances pane, choose Connect

In the Connect to instance pane, choose the Session Manager tab and then choose Connect

 A new browser tab opens with a shell terminal connection to the instance and displays Bourne Shell or “sh”, similar to this:


sh-4.2$
Now that you have accessed your EC2 instance we will install the freely available open source benchmarking tool needed to complete this lab.

Flexible IO Tester or FIO was created as a benchmarking tool for specific disk I/O workloads. You can run direct FIO commands via the command line with different parameters to benchmark your EBS volumes.

 Enter the following command to install FIO on the EC2 instance:

sudo yum install -y fio
Once the installation has completed you should see “Complete!” returned in the console and you are ready to move to the next task.

 For more information about Flexible IO Tester, refer to Welcome to FIO’s documentation! in the Additional resources section.

Task 3: Make Amazon EBS volumes available for use on Linux
Before you start benchmarking your volumes performance, we will create and mount a file systems on them to get a more accurate picture of the performance we can expect for our deployed application.

 Do not create a new file system your root volume i.e. for the device named xvda. Only create new file systems for your non-root volumes.

 Run the following command in the shell terminal to list information about all available block devices:

lsblk
 The output displays details about all available block devices, similar to this:


sh-4.2$ lsblk
NAME    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
xvda    202:0    0    8G  0 disk 
└─xvda1 202:1    0    8G  0 part /
xvdb    202:16   0  125G  0 disk 
xvdc    202:32   0  125G  0 disk 
xvdd    202:48   0    8G  0 disk 
xvde    202:64   0    8G  0 disk 
xvdf    202:80   0    8G  0 disk 
xvdg    202:96   0    8G  0 disk
 In this lab, you have:

One gp3 boot volume for your system files
Two st1 volumes dedicated for logs (Logs1 and Log2) with volume size of 125 GiB. Your application will be using these volumes for long sequential writes.
Four gp3 volumes dedicated for application data (Data1, Data2, Data3 and Data4) with a volume size of 8 GiB. Your application will be using these volumes primarily for small random reads and writes.
Note that the boot volume for your instance is assigned the first device NAME in the list, xvda. The next volumes listed are your Log volumes, with a size of 125G. The device name for your first logs volume is xvdb. After these, your data volumes are listed, with a size of 8G. Note the device name the first data volume listed, xvdd. We will use these devices to perform our first benchmarking tests.

Now that we know your device names, you will create file systems on the volumes and mount them. This is not strictly necessary. One can run performance benchmarks on unformatted devices. However, formatting the devices in the same way that they will be deployed in the production environment should give a more accurate picture of their future performance.

 Using the device name retrieved in the previous step, run the following command to create a file system on your log volume.

sudo mkfs -t xfs /dev/xvdb
The output of this command should look similar to the following to confirm successful file system creation.


meta-data=/dev/xvdb            		isize=512    agcount=4, agsize=524288 blks
         =                       	sectsz=512   attr=2, projid32bit=1
         =                       	crc=1        finobt=1, sparse=0
data   	 =                       	bsize=4096   blocks=2097152, imaxpct=25
         =                       	sunit=0      swidth=0 blks
naming   =version 2              	bsize=4096   ascii-ci=0 ftype=1
log      =internal log           	bsize=4096   blocks=2560, version=2
         =                       	sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   	extsz=4096   blocks=0, rtextents=0
 Run the following command to create a mount point directory for the volume. The mount point is where the volume is located in the file system tree and where you read and write files to after you mount the volume. The following creates a directory named /logs1.

sudo mkdir /logs1
 Run the following command to mount the volume at the directory you created in the previous step.

sudo mount /dev/xvdb /logs1
Repeat the above the three steps for your data volume.

Create an xfs file system on xvdd
Create a /data1 mount point
Mount your xvdd volume to your /data1 directory
 Use the list block devices (“lsblk”) command again to confirm the Data1 volume’s mountpoint.


lsblk
You should now see “/data1” and “/logs1” listed in the mountpoint column next to their respective devices.


sh-4.2$ lsblk
NAME    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
xvda    202:0    0    8G  0 disk 
└─xvda1 202:1    0    8G  0 part /
xvdb    202:16   0  125G  0 disk /logs1
xvdc    202:32   0  125G  0 disk 
xvdd    202:48   0    8G  0 disk /data1
xvde    202:64   0    8G  0 disk 
xvdf    202:80   0    8G  0 disk 
xvdg    202:96   0    8G  0 disk
 For more information about creating file systems on Linux, refer to Make an Amazon EBS volume available for use on Linux in the Additional resources section.

Task 4: Benchmarking your Volumes
In this task you start benchmarking your EBS volumes by running application I/O workloads using FIO.

TASK 4.0: ESTABLISH A SIMPLE PERFORMANCE BASELINE FOR LOG FILE VOLUME.
Our first benchmarking task is to establish a simple performance baseline for sequential writes to our logfile volume.

The application that your company has developed needs to write both to a primary working set of data, as well to a set of log files. The log file data will be written serially to a distinct set of volumes so that writes to the log files don’t interfere with IO to the primary data.

Your company has chosen to use lower cost, throughput optimized, st1 volumes to hold the log data. The st1 volume class offers throughput rates of 40 MiB/s per TB of allocated storage, and that offer burst throughput capacity of up to 250 MiB/s.

However, your company, in order to be extra frugal, has chosen to employ the minimum size of st1 volume available–125 GiB. These volumes offer throughput rates of 5 MiB/s with additional burst capacity up to 31 MiB/s.

Your company believes that 5 MiB/s should genrally be sufficient for its application’s log file writes but want you to verify that this can be achieved with the current infrastructure.

Therefore our first FIO benchmarking test will be looking at what is the observed throughput capacity of the minimum sized st1 volume?

To perform this benchmark test with FIO we will need to provide the following parameters:

–filename=(string)

This parameter specifies where (by device name) the test will be performed. We will use our logs1 device /dev/xvdb.

–direct=(bool)

This parameter controls if I/O should be buffered or not. To test disk performance, it should be set set to “1”, meaning direct disk access, without buffering.

–rw=(string)

This parameter specifies The I/O pattern to test.

Acceptable values:

read -> Sequential reads.
write -> Sequential writes.
randread -> Random reads.
randwrite -> Random writes.
rw, readwrite -> Mixed sequential reads and writes.
randrw -> Mixed random reads and writes.
For this test we will use “write” to test sequential writes.

–bs=(integer)

This parameter controls the size of the I/O. For this test our application engineers have told us to use a block size of 1MB.

–runtime=(integer)

This parameter defines the number of seconds the test will run before it terminates.

–allow_mounted_write=(bool)

By default, FIO will not allow write tests to mounted devices to insure pre-existing data is not over-written. By setting this parameter we will be able to write to our mounted volume.

–name=(string)

The name for test.

 Run the following command to perform 1 MB sequential write performance benchmark test on Lab-Volume-Logs1:

sudo fio --filename=/dev/xvdb --direct=1 --rw=write  --bs=1024k --runtime=180  --allow_mounted_write=1 --name=fio_task_4.0
 This benchmark test will take 180 seconds to complete. Note that while 60 seconds would give us an accurate picture of our achievable bandwidth through FIO in this case, the CloudWatch monitoring service polls the EBS service in one minute intervals. In order to confirm our results through CloudWatch, we should leave the runtime parameter at 180 seconds.

Once finished, the output of the above command will return a summary of the test results, which should look similar to this:

Task 5.3 Output

Examine the returned results from your benchmark test. You should specifically review the bw (bandwidth) return value on the line that starts with “write :” (highlighted in red box above). This value returns the observed throughput of the test.
In this test, a bandwidth of around 33000KB/s or 31 MiB/s should be seen.

Given 5 MiB/s was thought to be sufficient by your application developers, you can be confident that your st1 throughput optimized volume will be sufficient for your application logfile writes.

 For more information about FIO and different parameters used, refer to Welcome to FIO’s documentation! in the Additional resources section.

TASK 4.1: RUN A RANDOM WRITE BENCHMARK TEST ON YOUR DATA VOLUME.
The second benchmark test you need to run concerns the IOPS requirements of your application writes to the primary working data set. IOPS measures how many IO operations per second a given block storage device can handle.

The volume type your company is planning to use for primary application data is the gp3 volume. This volume type offers up to 3000 IOPS at no additional costs.

Therefore, for this test we want to examine how many IOPS are generated by the workload characteristics of our application on this instance class and see “are the observed IOPS less than 3000 IOPS”.

We can use the same parameters we used in the prior benchmarking test, however we will need to specify the data volume device (xvdd). Our application developers have told us that the application writes are typically 16 KB, so we will set the IO block size parameter to 16 KB (bs=16k). And we will need to change IO test profile to random writes (rw=randwrite), as this is the standard write profile of our application.

 Run the following command to perform a 16 KB random write performance test on your data volume:

sudo fio --filename=/dev/xvdd  --direct=1 --rw=randwrite  --bs=16k --runtime=120 --allow_mounted_write=1 --name=fio_task_4.1
 This test simulation will take 120 seconds to complete. Once finished, the output of the above command will return a summary of the test results, which should look similar to this:

Task 5.0 Output

Examine the returned results from your test. You should specifically review the IOPS number given at the top of the results summary (the line highlighted in red box above).
In this test, given we are working with a randomized workload, the IOPS value should be between 700-1100 IOPS.

This means that to support the write workload of our application (single threaded 16 KB random writes) on this instance class our volume will need to support 700-1100 IOPS.

Given that this is below 3000 IOPS offered by our gp3 volume, you can be confident that a single gp3 EBS volume will be able to handle your application’s primary data write workload without issue!

 Rerun the test again changing only the bs= parameter to a larger (64k) or smaller (8k) IO block size. What impact does this have on your IOPS requirements?
TASK 4.2: RUN A RANDOM READ TEST ON YOUR DATA VOLUME.
In addition to 16 KB writes, your developers have informed you that your application will often need to perform concurrent 4 KB reads on your data set.

Because of this, our third benchmarking test will simulate conditions of peak application read workloads on your EBS volume. To do this we will use FIO to generate multiple parallel random read requests on your data volume.

For this benchmarking test we will introduce two new parameters.

–numjobs=(int)

This parameter sets the number of parallel processes FIO will create. Your developer team has told you that during peak operations as many as six concurrent sessions maybe open to your working data set, so we will set this number to 6.

–group_reporting

Passing this parameter into the FIO test will result in a report that joins the results of the simultaneous jobs.

In addition to adding these two parameters, we will reduce the block size to 4k (bs=4k) to match the small IO requests that your read workload generates.

Given we are once again concerned with multiple small IO requests, IOPS will be the metric we are primarily concerned with. We want to see does your read workload hit the 3000 IOPS maximum of the gp3 volume?.

 Run the following command to perform parallel 4 KB random read tests on your data volume:

sudo fio --filename=/dev/xvdd --direct=1 --rw=randread --bs=4k --numjobs=6  --runtime=90 --group_reporting --name=fio_task_4.3
 The output of the above command should be similar to this:

Task 5.1 Output

Examine the returned results from this performance benchmarking test. You should again pay particular attention to the IOPS value on the line that starts with “read :” (highlighted in red box above).
In this test, you should see an IOPS value around 3000.

Comparing this with the result of the previous run, you see that a parallel random read workload hits the maximum 3000 IOPS that the gp3 volume type standardly offers.

This means that to serve the application’s maximum read requirement you will need to increase the IOPS capacity of the data volume.

 The IOPS capacity for a gp3 volume can be manually provisioned up to a maximum of 16,000 IOPS for an additional cost. Additionally, you could change your data volume to the io2 volume type to achieve IOPS of up 64,000.

Outside of provisioning additional IOPS or changing the volume type, in Task 6 below you will examine a performance optimization technique that will allow one to combine the IOPS capacity of multiple Amazon EBS volumes into a single logical volume.

Task 5: Use CloudWatch to review Throughput and IOPS performance.
In this task, you will review the CloudWatch metric graph widgets available within the EBS volumes console that relate to your volumes MiB/s and IOPS performance.

TASK 5.0: REVIEW BANDWIDTH PERFORMANCE DATA IN CLOUDWATCH
The CloudWatch metric graph widget that reports on your bandwidth and throughput performace is the Write bandwidth widget. In this task, you will review your MiB/s data in CloudWatch.

Return to the open EC2 console window in your browser. Open the left navigation pane, scroll down to the Elastic Block Store section and choose Volumes.

Remove the check from any volumes in your account list and select the checkbox next to Lab-Volume-Logs1.

Select the Monitoring tab for Lab-Volume-Logs1 in the pane below the volumes list.

You will see a number of different graphs of metric data related to your Data1 volume. These are the metrics automatically collected on your EBS volumes by the CloudWatch monitoring service.

Select the options menu next to the graph widget that says Write bandwidth, then select Enlarge.
Task 5.0 5.1a CW Metrics

Select 1 minute for the interval.
 Note that even though MiB/s is a per second metric insure you have set the metric interval to 1 minute. This specifies the polling interval for CloudWatch to use in calculating your MiB/s rate.

You should see a graph similar to the one below, with your Write bandwidth graph approaching the 33,000 KiB that was returned in your FIO results, and then hitting a plateau.

Task 5.0 5.1a CW Metrics

Close the Write bandwidth graph widget.

Remove the check from the Lab-Volume-Logs1

TASK 5.1: REVIEW IOPS PERFORMANCE THROUGH CLOUDWATCH
Your operations per second perforamnce is given in the CloudWatch widgets for Throughput. You will need to change the metric period to report on to 1-minute sums to view your operations per second.

Remove the checkbox next Lab-Volume-Logs1 and select the checkbox next to Lab-Volume-Data1.

Select the Monitoring tab for Lab-Volume-Data1 in the pane below the volumes list.

Select the options menu next to the graph that says Write throughput, then select Enlarge.

Select 1 minute for the interval.

 Note that even though IOPS is a per second metric insure you have set the metric interval to 1 minute. This specifies the polling interval for CloudWatch to use in calculating your IOPS rate.

 The graph displayed should return results that roughly match the performance benchmark test results that were returned for your random Write FIO tests.

Task 5.0 5.1 CW Metrics

 Note that your results will vary slightly from the reported IOPS in FIO. The CloudWatch service polls the EBS service in 1-minute intervals. For a small sample like our tests, it is unlikely that the polling intervals will align perfectly with the duration of test. The longer you run the test, the closer your results in CloudWatch should match the results reported by FIO.

Close the Write throughput graph.

Select the options menu next to the graph that says Read throughput and select Enlarge.

Select 1 minute for the interval.

This should display results for your second performance benchmarking test, with your IOPS performance approaching 3000.

Task 6: Optimize the performance of your Data volume through disk striping.
Disk striping is the process of creating a RAID 0 logical array through your operating system. This allows the operating system to treat multiple attached block devices as though they were a single device.

Spreading the I/O directed to a single logical volume across multiple EBS devices allows you to take advantage of their combined IOPS and throughput capacities.

Keep in mind that performance benefits offered by disk striping are limited by the worst performing volume in the set, and that the failure of any of the underlying EBS volumes will result in the failure of the logical volume.

 For more information about RAID, refer to RAID configuration on Linux in the Additional resources section.

Return to the session manager window in your broswer.
If the session manager browser window is closed, or session manager as terminated, you will need to return the Instances pane in the EC2 console, select your Lab instance, and select Connect

To create a RAID 0 array through the Linux operating system, we will use mdadm utility, specify a device name for our logical volume, and supply the three device names of the data volumes we have yet to employ.

 Use the following command to create a RAID 0 logical volume.

sudo mdadm --create --verbose /dev/md0 --level=0 --name=RAID_FROM_DATA --raid-devices=3 /dev/xvde /dev/xvdf /dev/xvdg
 The output will be similar to this:


mdadm: chunk size defaults to 512K
mdadm: Defaulting to version 1.2 metadata
mdadm: array /dev/md0 started.
Allow time for the RAID array to initialize and synchronize. You can track the progress of these operations with the following command:

sudo cat /proc/mdstat
 When the volume is ready you should see the “md0” device displayed as active:


Personalities : [raid0] 
md0 : active raid0 nvme3n1[2] nvme2n1[1] nvme5n1[0]
      25141248 blocks super 1.2 512k chunks
      
unused devices: <none>
Use the following command to display detailed information about your RAID array:

sudo mdadm --detail /dev/md0
 The following is an example output:


/dev/md0:
           Version : 1.2
     Creation Time : Mon Sep 27 07:03:52 2021
        Raid Level : raid0
        Array Size : 25141248 (23.98 GiB 25.74 GB)
      Raid Devices : 3
     Total Devices : 3
       Persistence : Superblock is persistent

       Update Time : Mon Sep 27 07:03:52 2021
             State : clean 
    Active Devices : 3
   Working Devices : 3
    Failed Devices : 0
     Spare Devices : 0

        Chunk Size : 512K

Consistency Policy : none

              Name : RAID_FROM_DATA
              UUID : f78c5ba3:18170192:c8c8fe99:1c14e590
            Events : 0

    Number   Major   Minor   RaidDevice State
       0     259        4        0      active sync   /dev/sde
       1     259        2        1      active sync   /dev/sdf
       2     259        1        2      active sync   /dev/sdg
 Create a file system on the RAID array. Run the following command to create an ext4 file system:

sudo mkfs.ext4 /dev/md0
Depending on the requirements of your application or the limitations of your operating system, you can use a different file system type, such as ext3 or XFS (check the file system documentation for the corresponding file system creation command).

 The following is example output:


mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=RAID_FROM_DATA
OS type: Linux
Block size=4096 (log=2)
Fragment size=4096 (log=2)
Stride=128 blocks, Stripe width=384 blocks
1572864 inodes, 6285312 blocks
314265 blocks (5.00%) reserved for the super user
First data block=0
Maximum filesystem blocks=2153775104
192 block groups
32768 blocks per group, 32768 fragments per group
8192 inodes per group
Superblock backups stored on blocks: 
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208, 
        4096000

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (32768 blocks): done
Writing superblocks and filesystem accounting information: done
 Run the following command to create a mount point for your RAID array:

sudo mkdir -p /mnt/raid
 Run the following command to mount the RAID device on the mount point that you created:

sudo mount /dev/md0 /mnt/raid
The RAID device is now ready for use and you can confirm that by running the following command as follows:


sudo lsblk
 The following is example output:


NAME    MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINT
xvda    202:0    0    8G  0 disk  
└─xvda1 202:1    0    8G  0 part  /
xvdb    202:16   0  125G  0 disk  
xvdc    202:32   0  125G  0 disk  
xvdd    202:48   0    8G  0 disk  /data1
xvde    202:64   0    8G  0 disk  
└─md0     9:0    0   24G  0 raid0 /mnt/raid
xvdf    202:80   0    8G  0 disk  
└─md0     9:0    0   24G  0 raid0 /mnt/raid
xvdg    202:96   0    8G  0 disk  
└─md0     9:0    0   24G  0 raid0 /mnt/raid
This output confirms that our three previously unused volumes are now jointly mounted on the /mnt/raid mountpoint.

TASK 6.1: RE-RUN YOUR RANDOM READ BENCHMARKING TEST.
In this task, we will re-run the performance benchmarking read workload on our RAID 0 data volume to see if we still run into the 3000 IOPS limit that we did before.

 Run the following command to perform 4 KB random read operations against RAID data device:

sudo fio --filename=/dev/md0 --direct=1 --rw=randread --bs=4k --numjobs=6  --runtime=60 --group_reporting --name=fio_task_6.1
 The following is an example output:

Task 5.5 Output

Examine the returned results from your benchmarking test. You should again focus on the IOPS value on the line that starts with “read :” (highlighted in red box above).
In this test, write IOPS of over 8000 should be observed. Compare this with your previous write benchmark of 3000

With the combined 3000 IOPS available for each of the three gp3 volumes, we now have access to 3X the IOPS capacity.

Congratulations! You have now optimized the performance of your primary data volume to triple its IOPS capacity!

Task 7: Challenge Task
 Challenge yourself! This challenge task allows you to test your knowledge of this lab. However, this task is optional and provided in case you have some time remaining.

Create a second RAID array (you can use device name /dev/md1) from the Log device volumes (Logs1 & Logs2). Refer to Task 6.0.

Re-test the sequential write load performance (task 4.0) on the RAID array created from Log volumes.

Compare the bandwidth results with the results from previous task. What performance improvement were you able to achieve?

 Note: Before creating a RAID array from Log device volumes, you need to unmount the Logs1 device that was mounted previously.


sudo umount -d /dev/xvdb
Conclusion
 Congratulations! You have successfully:

Tested the performance of different Amazon EBS volumes using FIO (Flexible IO Tester).
Used CloudWatch to monitor the performance of different EBS volume types.
Evaluated the suitability of different volume types suitable for your different application workloads.
Additional resources
Amazon Elastic Block Store (Amazon EBS)
What is Amazon CloudWatch?
AWS Systems Manager Session Manager
Welcome to FIO’s documentation!
NVMe CLI documentation
Make an Amazon EBS volume available for use on Linux
RAID configuration on Linux