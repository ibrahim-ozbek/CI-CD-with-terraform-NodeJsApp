•	Sample Problem

Create a CI/CD pipeline, so that whenever the code in commit in GitHub it will initiate CI/CD pipeline in Jenkins once it completes successfully then Jenkins will create a Docker image and will push Docker image to Docker hub.

•	Tools

Docker, Jenkins, GitHub

* How To Push a Docker Image To Docker Hub:

1. Create a Dockerfile for the application.

2. Build the application as an Image using Dockerfile.

3. Push the image to Docker Hub.

* Pre-requisite:

1. Jenkins server(installed on a cloud server)

2. Docker to be installed on the same Jenkins server.

3. Git account.

4. NodeJS on local computer.

5. Git on local computer.


* In this lesson we are going to see the following steps.

1.	Create GitHub Repo and Clone Locally.

2.	Create NodeJS Application.

3.	Get Secret Token From Docker Hub.

4.	Create New Pipeline Job in Jenkins.

5.	Create Dockerfile and Jenkinsfile

6.	Push Code To Github and Trigger Jenkins Job.


* Create Github Repo and Clone

** Create a repo in the Github. Assume the repo name is fdm-group.

``` bash
git clone URL of your repo
```
* Create NodeJS Application

``` bash
cd fdm-group
```
** Initiate the NodeJS application using the below command and fill in the prompted details. And then, install Express JS server.

``` bash
npm init
npm install express -save
```
** Create a file named server.js and paste the below code.

``` bash
const express = require("express");

const app = express();

//define port
const port=3000;

app.get("/", (req, res) => {

res.json({message:'This page is Root page'})

})

//get example

app.get("/get-data", (req, res) => {

res.json({message:'Get JSON Example'})

})

//run the application
app.listen(port, () => {
  console.log(`running at port ${port}`);
});
```
** Use the following command to run the NodeJS application locally.

``` bash
node server.js
```
** This will run the server on port 3000. So you can access it using the below URL.

http://localhost:3000/

# Now the demo application is ready. Next, we need to configure Jenkins to automate the Docker image creation. And we will use CloudFormation Template for Jenkins Server. 

``` bash
AWSTemplateFormatVersion: 2010-09-09

Description: >
  This Cloudformation Template creates a Jenkins Server on EC2 Instance.
  Jenkins Server is enabled with Git, Docker, AWS CLI Version 2
  Jenkins Server will run on Amazon Linux 2 EC2 Instance with
  custom security group allowing HTTP(80, 8080) and SSH (22) connections from anywhere.

Parameters:
  KeyPairName:
    Description: Enter the name of your Key Pair for SSH connections.
    Type: AWS::EC2::KeyPair::KeyName
    ConstraintDescription: Must one of the existing EC2 KeyPair
Resources:
  EmpoweringRoleforJenkinsServer:
    Type: "AWS::IAM::Role"
    Properties:
      AssumeRolePolicyDocument:
        Statement:
          - Effect: Allow
            Principal:
              Service:
              - ec2.amazonaws.com
            Action:
              - 'sts:AssumeRole'
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/AWSCloudFormationFullAccess
        - arn:aws:iam::aws:policy/AdministratorAccess
  JenkinsServerEC2Profile:
    Type: "AWS::IAM::InstanceProfile"
    Properties:
      Roles: #required
        - !Ref EmpoweringRoleforJenkinsServer
  JenkinsServerSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Enable SSH and HTTP for Jenkins Server
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0
        - IpProtocol: tcp
          FromPort: 8080
          ToPort: 8080
          CidrIp: 0.0.0.0/0
        - IpProtocol: tcp
          FromPort: 22
          ToPort: 22
          CidrIp: 0.0.0.0/0
  JenkinsServer:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: ami-0947d2ba12ee1ff75
      InstanceType: t3a.medium
      KeyName: !Ref KeyPairName
      BlockDeviceMappings:
        - DeviceName: /dev/xvda
          Ebs:
            VolumeType: gp2
            VolumeSize: '16'
      IamInstanceProfile: !Ref JenkinsServerEC2Profile
      SecurityGroupIds:
        - !GetAtt JenkinsServerSecurityGroup.GroupId
      Tags:                
        - Key: Name
          Value: !Sub ${AWS::StackName}-Jenkins-Server
        - Key: server
          Value: jenkins
      UserData:
        Fn::Base64: |
          #! /bin/bash
          # update os
          yum update -y
          # set server hostname as jenkins-server
          hostnamectl set-hostname jenkins-server
          # install git
          yum install git -y
          # install java 11
          yum install java-11-amazon-corretto -y
          # install jenkins
          wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat/jenkins.repo
          rpm --import https://pkg.jenkins.io/redhat/jenkins.io.key
          amazon-linux-extras install epel
          yum install jenkins -y
          systemctl daemon-reload
          systemctl start jenkins
          systemctl enable jenkins
          # install docker
          amazon-linux-extras install docker -y
          systemctl start docker
          systemctl enable docker
          usermod -a -G docker ec2-user
          usermod -a -G docker jenkins
          # configure docker as cloud agent for jenkins
          cp /lib/systemd/system/docker.service /lib/systemd/system/docker.service.bak
          sed -i 's/^ExecStart=.*/ExecStart=\/usr\/bin\/dockerd -H tcp:\/\/127.0.0.1:2375 -H unix:\/\/\/var\/run\/docker.sock/g' /lib/systemd/system/docker.service
          systemctl daemon-reload
          systemctl restart docker
          systemctl restart jenkins
          # install docker compose
          curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" \
          -o /usr/local/bin/docker-compose
          chmod +x /usr/local/bin/docker-compose
          # uninstall aws cli version 1
          rm -rf /bin/aws
          # install aws cli version 2
          curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
          unzip awscliv2.zip
          ./aws/install
          # install python 3
          yum install python3 -y
``` 

* Get Secret Token From Docker Hub

** Get the token using the following link.

https://hub.docker.com/settings/security

** Create an access token using the New Access Token button on the security page.
Copy the token. We can use this token and username to log in to the Docker hub using Jenkins.

* Create New Pipeline Job in Jenkins

Create a new Pipeline job by clicking the New Item and choose Pipeline.

**Then in the Pipeline definition, give Github URL and other corresponding values. It will automatically look for Jenkinsfile to execute commands. 
And mention the branch name and give file location of Jenkinsfile. I put the Jenkinsfile in the project root folder. So simply mention the Jenkinsfile in Script Path.

**Save this job. Automating Docker Image creation and push it to the Docker hub is done by using Jenkins. Now we need to create Dockerfile and Jenkinsfile. And push the code to the Git repo. The Jenkins job will be triggered automatically when a code changed in the Git repo.

* Create Dockerfile

**Create a file named Dockerfile on your NodeJS project folder and paste the code below.

``` bash
FROM node:13-alpine

RUN mkdir -p /home/app

COPY ./* /home/app/

WORKDIR /home/app

RUN npm install

CMD ["node", "server.js"]
``` 
* Create Jenkinfile

**Create a file named Jenkinsfile and paste the code below. This Jenkinsfile will be executed on the Jenkins server when the code is pushed to Github.

``` bash
pipeline{
	agent any

	environment {
		DOCKERHUB_CREDENTIALS=credentials('dockerhub-cred-fdm')
	}

	stages {

		stage('Build') {

			steps {
				sh 'docker build -t eaglehaslanded/myapp:latest .'
			}
		}

		stage('Login') {

			steps {
				sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
			}
		}

		stage('Push') {

			steps {
				sh 'docker push eaglehaslanded/myapp:latest'
			}
		}
	}
	post {
		always {
			sh 'docker logout'
		}
	}
}


```

* Push Code To Github and Trigger Jenkins Job

# That’s all. Everything is done. Now we need to test the Docker image creation and pushing it to the Docker hub.

** To test it push the code the Github repo using the following command.

``` bash
Git add .
Git commit -m “deploying-app”
Git push origin main
```

# When the code is pushed to Github, then the Jenkins pipeline job is triggered. And the pipeline job will take the Jenkinsfile and execute the code in the Jenkinsfile.  The build is triggered automatically in the pipeline job. Everything is successful. Now you can check the Docker hub. Your Docker image is uploaded.




