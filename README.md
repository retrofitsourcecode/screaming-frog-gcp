# screaming-frog-gcp
Here's a little BASH script I wrote to run Screaming Frog SEO spider on a GCP instance.

Based primarily upon the Fili Wiese article at https://searchengineland.com/how-to-run-screaming-frog-seo-spider-in-the-cloud-in-2019-317416 and with a lot of help from Google and Stack Overflow, of course.

Once you've followed the instructions in the Fili Wiese article and have a GCP instance that can run Screaming Frog, this script will run Screaming Frog with whatever config file you specify.  The results can then be compressed and saved to a GCP bucket.  You may also instruct the machine to shut itself down to save runtime costs.

This script in a crontab, coupled with a startup instance schedule in GCP should allow fairly efficient crawling of a site.

There are certainly improvements possible.  Email notifications for one.  Not having the GCP bucket hardcoded to my bucket for another.  It's my first BASH script, so...
