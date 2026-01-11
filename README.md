# meeting #1 - my-armageddon-project-1
### Group Leader: Omar Fleming
### Team Leader: Larry Harris
### Date: 01-04-25 (Sunday)
### Time: 2pm - 4:30 est.
----

### Members present: 
- Larry Harris
- Kelly D Moore
- Dennis Shaw
- Logan T
- Tre Bradshaw
- Bryce Williams
- Jasper Shivers (Jdollas)
- Ted Clayton
- Torray
- Zeek-Miller
- Jay Mallard

-----
### In today's meeting:
- created and instructed everyone to create a Terraform repo in Github to share notes and test the Terraform builds
- went through Lab 1a discussed, seperated Larry's main.tf into portions. We tested trouble shot, spun up the code. Dennis will upload to github and after Larry looks through it, will make it available for everyone to download
- everyone inspect, test and come back with any feedback, suggestions and or comments
- Here is the 1st draft diagram. We want to hear if you guys have any feedback or suggestions for this as well.

-------
### Project Infrastructure
VPC name  == bos_vpc01  
Region = US East 1   
Availability Zone
- us-east-1a
- us-east-1b 
- CIDR == 10.26.0.0/16 

|Subnets|||
|---|---|---|
|Public|10.26.101.0/24|10.26.102.0/24|  
|Private|10.26.101.0/24| 10.26.102.0/24|

-------
### .tf file changes 
- Security Groups for RDS & EC2

    - RDS (ingress)
    - mySQL from EC2

- EC2 (ingress)
    - student adds inbound rules (HTTP 80, SSH 22 from their IP)

*** reminder change SSH rule!!!

-------------
# meeting #2 - my-armageddon-project-1
### Group Leader: Omar Fleming
### Team Leader: Larry Harris
### Date: 01-05-25 (Monday)
### Time: 5pm - 8pm est.
----
### Members present: 
- Larry Harris
- Dennis Shaw
- Jasper Shivers (Jdollas)
- David McKenzie
- Ted Clayton
- LT (Logan T)
______

### In today's meeting

- Review meeting 1
- make sure everyone has their github setup

----
### Fixes
- #### ERROR notice!!!
    - note - recursive error when you re-upload this build you will get an error:
    - "You can't create this secret because a secret with this name is already scheduled for deletion." AWS keeps the secret by default for 30 days after you destroy. Therefore run this code to delete now after each terraform destroy

>>aws secretsmanager delete-secret --secret-id bos/rds/mysql --force-delete-without-recovery

- #### changes from week 1 files:
  - variables.tf - line 40 verify the correct AMI #
  - variables.tf - line 46 verfify if you are using T2.micro or T3.micro
  - variables.tf - line 83 use your email
  - delete providers.tf because it is duplicated in the auth.tf 
  - output.tf - line command out the the last two blocks (line 22-27)
  - JSON file - replace the AWS account with your personal 12 digit AWS account#

---------
### Deliverables
- go through the [expected lab 1a deliverables](https://github.com/DennistonShaw/armageddon/blob/main/SEIR_Foundations/LAB1/1a_explanation.md). Starting at #4 on the 1a_explanation.md in Theo's armageddon.

#### Architectural Design 

Theo's outline

- showing the logical flow 
  - A user sends an HTTP request to an EC2 instance
  - The EC2 application:
  - Retrieves database credentials from Secrets Manager
  - Connects to the RDS MySQL endpoint
  - Data is written to or read from the database
  - Results are returned to the user
- and satisfying the security model
  - RDS is not publicly accessible
  - RDS only allows inbound traffic from the EC2 security group
  - EC2 retrieves credentials dynamically via IAM role
  - No passwords are stored in code or AMIs

My flow query  

 - user -> the internet gateway attached to the VPC to the EC2 inside an AZ us-east-1a inside a Public Subnet, the EC2 has IAM roles attached, also, the EC2 in the public subnet -> SNS inside the Region US East 1 to the email Alert system administered by the SNS outside the Region east 1, also, the EC2 -> to the VPC endpoint -> secrets manager inside region US East 1 but outside of the AZ of us-east-1a, -> RDS inside the Private subnet inside us-east-1a -> Nat Gateway to the internet gateway to the user

Verified flow concept

1. User request is initiated from the internet.
2. The request passes through the Internet Gateway (IGW) attached to the VPC.
3. The traffic is routed to the EC2 instance in the public subnet (using its public IP/DNS).
4. The EC2 instance processes the request, communicates internally with Secrets Manager via a VPC endpoint to retrieve database credentials, and then connects to the RDS instance in the private subnet to query or store data.
5. The RDS instance sends the data back to the EC2 instance over the private network.
6. The EC2 instance generates a response and sends it back out through the Internet Gateway (IGW) to the User over the internet.
7. Separately, if an alert is triggered, the EC2 instance connects to the SNS regional endpoint (either via the IGW or a separate VPC endpoint) to send a notification, which SNS then delivers to the external email system. The NAT gateway is not typically involved in either of these primary request/response paths. 

screen capture (sc)<sup>1</sup>![first draft diagram](./screen-captures/lab1a-diagram.png)

-----

A. Infrastructure Proof
  1) EC2 instance running and reachable over HTTP
   
sc<sup>0</sup>![RDS-SG-inbound](./screen-captures/0.png)

  2) RDS MySQL instance in the same VPC

sc<sup>3</sup>![3 - init](./screen-captures/3.png)
   
  3) Security group rule showing:
       - RDS inbound TCP 3306
      - Source = EC2 security group (not 0.0.0.0/0)  
  
  IAM role attached to EC2 allowing Secrets Manager access

sc<sup>00</sup>![IAM role attached](./screen-captures/00.png)

Screenshot of: RDS SG inbound rule using source = sg-ec2-lab EC2 role attached 

sc<sup>1</sup>![RDS-SG-inbound](./screen-captures/1.png)

### B. Application Proof
  1. Successful database initialization
  2. Ability to insert records into RDS
  3. Ability to read records from RDS
  4. Screenshot of:
     - RDS SG inbound rule using source = sg-ec2-lab
     - EC2 role attached

- http://<EC2_PUBLIC_IP>/init

sc<sup>3</sup>![3 - init](./screen-captures/3.png)

- http://<EC2_PUBLIC_IP>/add?note=first_note

sc<sup>4</sup>![4 - add?note=first_note](./screen-captures/4-note-1.png)

- http://<EC2_PUBLIC_IP>/list

sc<sup>7</sup>![7 - list](./screen-captures/7-list.png)

  - If /init hangs or errors, it’s almost always:
    RDS SG inbound not allowing from EC2 SG on 3306
    RDS not in same VPC/subnets routing-wise
    EC2 role missing secretsmanager:GetSecretValue
    Secret doesn’t contain host / username / password fields (fix by storing as “Credentials for RDS database”)

- list output showing at least 3 notes

sc<sup>5</sup>![5 - add?note=2nd_note](./screen-captures/5-note-2.png)

sc<sup>6</sup>![6 - add?note=3rd_note](./screen-captures/6-note-3.png)

-----
### C. Verification Evidence
- CLI output proving connectivity and configuration
- Browser output showing database data
- Copy and paste this command your vscode terminal 

>>>mysql -h bos-rds01.cmls2wy44n17.us-east-1.rds.amazonaws.com -P 3306 -u admiral -p 

- (you can get this from the command line in vscode in the output section)

sc<sup>10</sup>![10 - CLI proof and databas data](./screen-captures/10.png)

------

Connect to AWS CLI

- go to instances > connect > Session manager (because its in a private subnet you can't access this though public internet) > connect

sc<sup>8</sup>![8 - connect to CLI 1](./screen-captures/8.png)

sc<sup>9</sup>![9 - connect to CLI 2](./screen-captures/9.png)


------
## 6. Technical Verification 

### 6.1 Verify EC2 Instance
run this code in terminal

>>>aws ec2 describe-instances --filters "Name=tag:Name,Values=bos-ec201" --query "Reservations[].Instances[].{InstanceId:InstanceId,State:State.Name}"

#### Expected:
  - Instance ID returned  
  - Instance state = running

sc<sup>17</sup>![EC2 id & state running](./screen-captures/17.png)


### 6.2 Verify IAM Role Attached to EC2
>>>aws ec2 describe-instances \
  --instance-ids <INSTANCE_ID> \
  --query "Reservations[].Instances[].IamInstanceProfile.Arn"

#### Expected:
- ARN of an IAM instance profile (not null)

sc<sup>18</sup>![ARN of an IAM](./screen-captures/18.png)


### 6.3 Verify RDS Instance State
>>>aws rds describe-db-instances \
  --db-instance-identifier bos-rds01 \
  --query "DBInstances[].DBInstanceStatus"

#### Expected 
  Available

sc<sup>19</sup>![Available](./screen-captures/19.png)

### 6.4 Verify RDS Endpoint (Connectivity Target)
>>>aws rds describe-db-instances \
  --db-instance-identifier bos-rds01 \
  --query "DBInstances[].Endpoint"

#### Expected:
- Endpoint address
- Port 3306

sc<sup>20</sup>![Endpoint address and port 3306](./screen-captures/20.png)

----   
### 6.5 (works)

>>>aws ec2 describe-security-groups --filters "Name=tag:Name,Values=bos-rds-sg01" --query "SecurityGroups[].IpPermissions"
         
#### Expected: 
- TCP port 3306 
- Source referencing EC2 security group ID, not CIDR

sc<sup>21</sup>![TCP Port and EC2 security group ID](./screen-captures/21.png)

----  
### 6.6 (run command inside ec2 sessions manager) (works)
SSH into EC2 and run:

>>>aws secretsmanager get-secret-value --secret-id bos/rds/mysql
expected result
                
                
#### Expected: 
- JSON containing: 
  - username 
  - password 
  - host 
  - port
        

sc<sup>22</sup>![JSON containing info](./screen-captures/22.png)

---------

### 6.7 Verify Database Connectivity (From EC2)
Install MySQL client (temporary validation):
sudo dnf install -y mysql

#### Connect: this next command 6.7 was aready added into the user data therefore no need to run now. See line 4 in user data
>>>mysql -h <RDS_ENDPOINT> -u admin -p

  - to get the rds endpoint:
  - go to consol and connect instance. Code must be run in the AWS terminal (connect > session manager > connect)
  - go to consol > rds > databases > DB identifier > connectivity and security - then copy endpoint paste in code. Enter password Broth3rH00d hit return

sc<sup>23</sup>![MySQL](./screen-captures/23.png)

Expected:
- Successful login
- No timeout or connection refused errors

------

### 1. Short answers:  

- A. Why is DB inbound source restricted to the EC2 security group? 
  - Restricting database inbound traffic to an EC2 security group is a fundamental security best practice
   
- B. What port does MySQL use?  
  - Port 3306
  
- C. Why is Secrets Manager better than storing creds in code/user-data?
  - It centrally stores, encrypts, and manages secrets with automatic rotation and fine-grained access controls, eliminating hardcoded credentials in code/user-data, which significantly reduces the risk of exposure and simplifies lifecycle management. 

-------------
# meeting #3 - my-armageddon-project-1
### Group Leader: Omar Fleming
### Team Leader: Larry Harris
### Date: 01-06-25 (Tuesday)
### Time: 8:00pm -  11:15pm est.
---------
### Members present: 
- Larry Harris
- Dennis Shaw
- Kelly D Moore
- Bryce Williams
- Eugene
- LT (Logan T)
- NegusKwesi
- Torray
- Tre Bradshaw
- Ted Clayton
-------------


### Fixes:

inline_policy.json  

<sup>15</sup>![json fix](./screen-captures/15-json-fix.png)

ec2.tf

- line 19 create an IAM policy referencing the json from our folder
- comment out line 26-29 in ec2.tf
----
add:
resource "aws_iam_role_policy" "bos_ec2_secrets_access" {
  name = "secrets-manager-bos-rds"
  role = aws_iam_role.bos_ec2_role01.id

  policy = file("${path.module}/00a_inline_policy.json")
}

<sup>16</sup>![json fix](./screen-captures/16.png)

- make sure everyone is caught up
- go over all deliverables so that everyone can take screenshots
----------

# Lab 1a complete!

# Lab 1b
01-08-25 
quick meeting with Larry with some updates for Lab 1b

### Add files:
  
- ### lambda_ir_reporter.zip
  - the zip will run on initializing
----
- ### lambda (folder)
  - copy and add the two files from the Lambda folder in Larry's repo
    1. claude.py
    2. handler.py
----
- ### 1a_user_data.sh 
  - replaced current contents with Larry's
----
- ### bedrock_autoreport.tf
----
- ### cloudwatch.tf folder copy and past code from Larry
----
- ### go to output.tf file
  - un Toggle Line Comment last 2 output blocks
----
- ### sns_topic.tf 
  - copy from Larry's repo
----


****** note: will start testing tomorrow, and going through familiarizng myself with the deliverables. 
- when I see "lab" in the commands I have to change to bos_ec01

-----
----
Friday 01-09-25  
5pm - 8pm  
caught up more members

------

------

# Final Check for lab 1a:
Saturday 01-10-25
re:
- https://github.com/DennistonShaw/armageddon/blob/main/SEIR_Foundations/LAB1/1a_final_check.txt

1) From your local Terminal we are changing permissions for the following files to run (metadata checks; role attach + secret exists)

>>>     chmod +x gate_secrets_and_role.sh

>>>     chmod +x gate_network_db.sh

>>>     chmod +x run_all_gates.sh

sc<sup>24-1</sup>![24](./screen-captures/24-1.png)

>>>     REGION=us-east-1 INSTANCE_ID=i-0123456789abcdef0 SECRET_ID=my-db-secret ./gate_secrets_and_role.sh

- change_instance ID and Secret_ID and run
- these are my personal IDs (get yours from the console or terminal)
  - instance ID: i-0d5a37100e335070c
  - secrets ID: bos/rds/mysql\
  - DB_ID: bos-rds01

sc<sup>24-2</sup>![24](./screen-captures/24-2.png)

---------

### 1) Basic: verify RDS isn’t public + SG-to-SG rule exists

>>>    REGION=us-east-1 INSTANCE_ID=i-0123456789abcdef0 DB_ID=mydb01 ./gate_network_db.sh

ID Changes:
  - instance ID: i-0d5a37100e335070c
  - secrets ID: bos/rds/mysql\
  - DB_ID: bos-rds01

sc<sup>24-4</sup>![24](./screen-captures/24-4.png)

----

### 2) Basic: verify RDS isn’t public + SG-to-SG rule exists
Strict: also verify DB subnets are private (no IGW route)

>>>REGION=us-east-1 \
INSTANCE_ID=i-0123456789abcdef0 \
SECRET_ID=my-db-secret \
DB_ID=mydb01 \
./run_all_gates.sh

ID Changes:
  - instance ID: i-0d5a37100e335070c
  - secrets ID: bos/rds/mysql\
  - DB_ID: bos-rds01

sc<sup>24-5</sup>![24](./screen-captures/24-5.png)

----

## Strict options (rotation + private subnet check)

### Expected Output:
Files created:
- gate_secrets_and_role.json
- gate_network_db.json
- gate_result.json ✅ combined summary

Exit code: you will see these in the Python (folder) > gate_result.json
- 0 = ready to merge / ready to grade
- 2 = fail (exact reasons provided)
- 1 = error (missing env/tools/scripts)

sc<sup>24-6</sup>![24](./screen-captures/24-6.png)