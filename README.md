# terraform-project
My first terraform project
Please find the attached terraform code and terraform-project.docx for more details,

# Commission and decommission the infrastructure with just one command.
# This script creates a VPC with 4 subnets ie 1Public and 1Private each in 2 different availability zone.
# Route table and association and internet to the public routing is also done.
# A security group is also created allowing ssh, http and https.
# Creates 2 instances webserver1 and webserver2 in public subnets in both the availability zone. User data has been passed from files (install_httpd1 and install_httpd2) to install http and display a message on the url.
# A classic ELB is also created to load balance the request. A bucket should be already created in our account with public access or a instance role should be created to have permission to communicate with S3 service.
# The ElB URL can be mapped with route53 to serve requests from (www.example.com) - This has not been done in this script as i have not purchased any domain.

For More details, Refer terrafor-project.docx file.
