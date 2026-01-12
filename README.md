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

-----

### In today's meeting

- Review meeting 1
- make sure everyone has their github setup

----

### Fixes
- #### ERROR notice!!!
    - note - recursive error when you re-upload this build you will get an error:
    - "You can't create this secret because a secret with this name is already scheduled for deletion." AWS keeps the secret by default for 30 days after you destroy. Therefore run this code to delete now after each terraform destroy

>>>aws secretsmanager delete-secret --secret-id bos/rds/mysql --force-delete-without-recovery

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

### A. Infrastructure Proof
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

------------

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

-------

### 6.2 Verify IAM Role Attached to EC2
>>>aws ec2 describe-instances \
  --instance-ids <INSTANCE_ID> \
  --query "Reservations[].Instances[].IamInstanceProfile.Arn"

#### Expected:
- ARN of an IAM instance profile (not null)

sc<sup>18</sup>![ARN of an IAM](./screen-captures/18.png)

----------

### 6.3 Verify RDS Instance State
>>>aws rds describe-db-instances \
  --db-instance-identifier bos-rds01 \
  --query "DBInstances[].DBInstanceStatus"

#### Expected 
  Available

sc<sup>19</sup>![Available](./screen-captures/19.png)

----------

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

----------
----------

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


*note: will start testing tomorrow, and going through familiarizng myself with the deliverables. 
- when you see "lab" in the commands I have to change to bos_ec01

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
- *note: everytime you spin up the instance ID changes
  - instance ID: i-0d5a37100e335070c
  - secrets ID: bos/rds/mysql
  - DB_ID: bos-rds01

sc<sup>24-2</sup>![24](./screen-captures/24-2.png)

---------

### 1) Basic: verify RDS isn’t public + SG-to-SG rule exists

>>>    REGION=us-east-1 INSTANCE_ID=i-0123456789abcdef0 DB_ID=mydb01 ./gate_network_db.sh

ID Changes:
  - instance ID: i-0d5a37100e335070c
  - secrets ID: bos/rds/mysql
  - DB_ID: bos-rds01

sc<sup>24-4</sup>![24](./screen-captures/24-4.png)

----

### 2) Basic: verify RDS isn’t public + SG-to-SG rule exists
Strict: also verify DB subnets are private (no IGW route)

- *note: when pushed to github the backslashes "\" do not appear. Remember to add a space + \ at the end of each line where a new line follows

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

if you get this error message, copy the URL, go to github and change your 
https://github.com/settings/emails

sc<sup>24-7</sup>![24-7 email fix 1](./screen-captures/24-7-email-fix-1.png)


sc<sup>24-8</sup>![24-8 email fix 2](./screen-captures/24-8-email-fix-2.png)

--------

# meeting #4 - my-armageddon-project-1
### Group Leader: Omar Fleming
### Team Leader: Larry Harris
### Date: 01-10-25 (Saturday)
### Time: 2:00pm -  3:00pm est. in class
### Time: 3:00pm -  6:00pm est. with group

---------

### Members present: 
- Larry Harris
- Dennis Shaw
- Kelly D Moore
- LT (Logan T)
- Torray
- Zeek-Miller314
- David McKenzie
- Ted Clayton
- Jasper
- Tre Bradshaw
- Roy Lester
- Jasper Shivers (Jdollas)

-------------

#### 3 things to change in the following codes
- ARN  
- anywhere it says "lab" in the code replace it with "bos"

------------

- catch everyone up and confirm Lab 1a is complete
- go over lab 1b notes

------------

PART I — Incident Scenario 

#### Breaking the system
- pull up url+ / init to see the page is working

sc<sup>25</sup>![25](./screen-captures/25.png)

- go to secrets manager in the consol > click secrets name > overview > click retrieve secrets value > edit > plaintext > make a change to the password (break the password)

sc<sup>26</sup>![26](./screen-captures/26.png)

- go back to the URL add /line to confirm it's broken

sc<sup>27</sup>![27](./screen-captures/27.png)

#### PART III — Monitoring & Alerting (SNS + PagerDuty Simulation)
SNS Alert Channel SNS Topic Name: lab-db-incidents aws sns create-topic --name lab-db-incidents Email Subscription (PagerDuty Simulation)

----

 >>>aws sns subscribe \
   --topic-arn <TOPIC_ARN> \
   --protocol email \
   --notification-endpoint your-email@example.com

*remember to put " \ at the end of every line except the last
 
get ARN: go to consol > SNS > Topic > copy ARN
my personal ARN: 
- arn:aws:sns:us-east-1:497589205696:bos-db-incidents

- change email
- confirm in your email that you have subscribed
  
sc<sup>28-1</sup>![28-1](./screen-captures/28-1.png)

----

If you are having an issue subscribing to the SNS because it automatically unsubscribes then:
- redo the steps to get an email confirmation (DO NOT CONFIRM!) 
- subcribe manually through the consol by going to Amazon SNS > Subscriptions select the pending confirmation and confirm subscription.
- it will ask you to enter the subscription confirmation url
    - go your email open, right click the confirm subscription link and copy the address/url
    - go back to consol and past this into the "Enter the subscription conformation url" box
    - confirm
  
sc<sup>28-2</sup>![28-2](./screen-captures/28-2.png)

sc<sup>28-3</sup>![28-3](./screen-captures/28-3.png)

----

CloudWatch Alarm → SNS Alarm Concept Trigger when: DB connection errors ≥ 3 in 5 minutes Alarm Creation (example)

*the original code in Theo's instructions didn't work. We found this new code and replaced it.

>>>aws cloudwatch put-metric-data \
    --namespace bos/RDSApp \
    --metric-name DBConnectionErrors \
    --value 5 \
    --unit Count

Expected results:
- email alert

sc<sup>29</sup>![29](./screen-captures/29.png)

- *note: you can also click the link in the email to view the alarm parameters in more detail in AWS console

sc<sup>30-1</sup>![30-1](./screen-captures/30-1.png)

sc<sup>30-2</sup>![30-2](./screen-captures/30-2-history-data-alarm.png)

sc<sup>30-3</sup>![30-3](./screen-captures/30-3-history-data-ok.png)

----

### RUNBOOK SECTION 2 - Observe 2.1 Check Application Logs

>>>aws logs filter-log-events \
  --log-group-name /aws/ec2/lab-rds-app \
  --filter-pattern "ERROR"

Expected: Clear DB connection failure messages

sc<sup>31</sup>![31](./screen-captures/31.png)

----

#### 2.2 Identify Failure Type Students must classify:

- Credential failure? Network failure? Database availability failure? This classification is graded.

RUNBOOK SECTION 3 — Validate Configuration Sources 3.1 Retrieve Parameter Store Values

>>>  aws ssm get-parameters \
    --names /lab/db/endpoint /lab/db/port /lab/db/name \
    --with-decryption

Expected: Endpoint + port returned

sc<sup>32</sup>![32](./screen-captures/32.png)

----

3.2 Retrieve Secrets Manager Values

>>>aws secretsmanager get-secret-value \
  --secret-id lab/rds/mysql

Expected: Username/password visible Compare against known-good state

sc<sup>33-1</sup>![33-1](./screen-captures/33-1.png)

------

RUNBOOK SECTION 4 — Containment 4.1 Prevent Further Damage Do not restart EC2 blindly Do not rotate secrets again Do not redeploy infrastructure

Students must explicitly state: “System state preserved for recovery.”

- basically fix the password

sc<sup>33-2</sup>![33-2](./screen-captures/33-2.png)

------

RUNBOOK SECTION 5 — Recovery Recovery Paths (Depends on Root Cause) If Credential Drift Update RDS password to match Secrets Manager OR Update Secrets Manager to known-good value

If Network Block
- Restore EC2 security group access to RDS on 3306

If DB Stopped
- Start RDS and wait for available

check url

Verify Recovery 
>>> curl http://<EC2_PUBLIC_IP>/list

Expected: Application returns data No errors

sc<sup>34</sup>![34](./screen-captures/34.png)

sc<sup>35</sup>![35](./screen-captures/35.png)

-------

RUNBOOK SECTION 6 — Post-Incident Validation 6.1 Confirm Alarm Clears

#### It wouldn't work - group solution

Run this command first, wait 5 minutes (300) after running the code which creates a second alarm to check afer we fix it.

>>>aws cloudwatch put-metric-alarm    --alarm-name bos-db-connection-success    --metric-name DBConnectionErrors    --namespace Bos/RDSApp    --statistic Sum    --period 300    --threshold 3    --comparison-operator GreaterThanOrEqualToThreshold    --evaluation-periods 1 --treat-missing-data notBreaching  --alarm-actions arn:aws:sns:us-east-1:497589205696:bos-db-incidents

run this to verify OK

>>>aws cloudwatch describe-alarms \
  --alarm-names bos-db-connection-success \
  --query "MetricAlarms[].StateValue"

sc<sup>36</sup>![36](./screen-captures/36.png)

Expected: OK

------

6.2 Confirm Logs Normalize

>>>aws logs filter-log-events \
  --log-group-name /aws/ec2/lab-rds-app \
  --filter-pattern "ERROR"

Expected: No new errors

sc<sup>37</sup>![37](./screen-captures/37.png)

-----


----

# meeting #5 - my-armageddon-project-1
### Group Leader: Omar Fleming
### Team Leader: Larry Harris
### Date: 01-11-25 (Sunday)
### Time: 2:00pm - 2:30pm est. in class
### Time: 3:00pm -  pm est. with group

---------

### Members present: 
- Larry Harris
- Dennis Shaw
- Kelly D Moore
- LT (Logan T)
- Roy Lester
- Rubeen Perry
- Ted Clayton
- Torray
- Tre Bradshaw
- David McKenzie
- Jasper Shivers (Jdollas)

---------

### In today's meeting:

- we went through Theo's instructions for Lab 1b

------------

# Final requirements for Lab 1b

### ALARM: "bos-db-connection-failure" in US East (N. Virginia)

We received this email because Amazon CloudWatch Alarm "bos-db-connection-failure" in the US East (N. Virginia) region has entered the ALARM state; "Threshold Crossed: 1 datapoint [5.0 (11/01/26 18:01:00)] was greater than or equal to the threshold (3.0)." at "Sunday 11 January, 2026 18:06:54 UTC".

### Incident Report: bos-db-connection-failure
|Field|Description|
|---|---|
|Region: |US East (N. Virginia)|
|AWS Account: | 497589205696|
|Alarm Arn: | arn:aws:cloudwatch:us-east-1:497589205696:alarm:bos-db-connection-failure|
|||
|||
|STATE CHANGE: | INSUFFICIENT_DATA -> ALARM|
|Reason for State Change: | *The password was changed resulting in:* Threshold Crossed: datapoint [5.0 (11/01/26)] was greater than or equal to the threshold (3.0).|
|Date/Time of Incident|Sunday 11, January, 2026 / 18:06:54 UTC: |
|||
|||
|STATE CHANGE: |INSUFFICIENT_DATA -> OK|
|Reason for State Change: |*Corrected the password.**|
|Date/Time of Incident |Sunday 11, January, 2026 / 22:03:38 (UTC)|


A comprehensive investigation determined that the AWS Secrets Manager password had been modified without authorization. The password has since been restored to its correct value. To prevent a recurrence we will review and refine IAM policies to ensure adherence to the principle of least privilege.

The following actions are recommended:
- Implement multi-factor authentication (MFA) to provide an additional layer of security, and enable AWS CloudTrail to capture and retain records of all API calls and user activity.
- Reduce mean time to resolution (MTTR) by deploying Amazon CloudWatch Synthetics canaries to continuously monitor critical endpoints and APIs.

----


