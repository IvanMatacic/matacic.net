---
title: "How Proper Storage Optimization Settings Can Save You Money"
date: 2024-01-15
lastmod: 2024-05-08
topics: ["Veeam"]
tags: ["backup", "object-storage", "s3", "vmware"]
summary: "Understanding the true cost of object storage is crucial, especially when considering the often-overlooked hidden costs. Learn how proper storage optimization settings can save you money."
slug: "proper-storage-optimization"
draft: false
---

I was inspired with [blog post](https://community.veeam.com/blogs-and-podcasts-57/object-storage-impact-of-job-storage-optimization-settings-in-v11-2601) from Veeam Community which in depth explains impact of storage optimization settings on backup size and number of objects. Other [blog post](https://www.veeam.com/blog/cloud-object-storage-benchmarks.html) explains more the cost side, but it wasn't enough for me. I want to test it in real environment.

## Test setup

For this test I used 4 backup jobs, every with different Storage optimization settings: 256 kB, 512 kB, 1 MB and 4 MB and all with High Compression level. Remain configuration is the same for all jobs; Forever Forward Incremental mode and Changed Block Tracking (CBT). The setup involved three virtual machines: a low-load Windows Server 2022 with an Active Directory Domain Controller role, a Linux VM serving as a jumphost, and a Mikrotik CHR. Every job has their own AWS S3 bucket provisioned as Backup Repository in direct Connection mode.

## Results

After 22 days, the data revealed intriguing cost implications. While each block size showing pretty much the same numbers of GET requests, number of PUT requests was significantly different. All of this resulting in differing costs.

| Block Size | Total number of GET Requests | Total number of PUT Requests | Cost of GET Requests | Cost of PUT Requests | Total Requests Cost (GET+PUT) | Bucket size in GB | Bucket cost | Total cost |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 256 kB | 65341 | 429608 | 0,028 | 2,320 | 2,348 | 21,06 | 0,052 | 2,400 |
| 512 kB | 65348 | 310749 | 0,028 | 1,678 | 1,706 | 23,19 | 0,057 | 1,763 |
| 1 MB | 68821 | 252203 | 0,030 | 1,362 | 1,391 | 26,45 | 0,065 | 1,456 |
| 4 MB | 65346 | 185007 | 0,028 | 0,999 | 1,027 | 38,28 | 0,094 | 1,121 |

All costs are in USD and are calculated by AWS prices at the day of writing this post. Region was Europe (Frankfurt) and S3 Standard bucket. For easier calculation, Bucket size represents bucket usage on last day for which I took metrics.

![Stacked bar chart of total cost in USD per block size, split into request cost and bucket cost](/images/proper-storage-optimization/cost-1.png)

Let's see how it looks in percentages compared to recommended 1 MB block size:

| Block Size | All Requests Cost | All Requests Cost Diff | Bucket Cost | Bucket Cost Diff | Total Cost | Total Cost Diff |
| --- | --- | --- | --- | --- | --- | --- |
| 256 kB | 2,348 | 169% | 1,135 | 80% | 3,483 | 124% |
| 512 kB | 1,706 | 123% | 1,250 | 88% | 2,956 | 105% |
| 1 MB | 1,391 | 100% | 1,426 | 100% | 2,817 | 100% |
| 4 MB | 1,027 | 74% | 2,063 | 145% | 3,090 | 110% |

Just as Veeam recommend, 1 MB block size was optimal block size in my case too.

Next, I plan to extend this investigation by testing various compression settings, aiming to further demystify the cost dynamics of object storage in practical settings.
