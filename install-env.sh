#!/bin/bash

# module-08 sample code

# Add comment and link describing NodeJs install
# Installing Nodejs 22

# Node JS Package List URL Link: https://github.com/nodesource/distributions?tab=readme-ov-file#using-debian-as-root-nodejs-22
sudo apt update -y
sudo apt-get install -y curl nginx

# Get the URL of the package
curl -fsSL https://deb.nodesource.com/setup_20.x -o nodesource_setup.sh

sudo -E bash nodesource_setup.sh

# Install Node JS
sudo apt-get install -y nodejs

# Print out output
node -v

##############################################################################
# Use NPM (node package manager to install AWS JavaScript SDK)
##############################################################################
# Run NPM to install the NPM Node packages needed for the code
# You will start this NodeJS script by executing the command: node app.js
# from the directory where app.js is located. The program `pm2` can be
# used to auto start NodeJS applications (as they don't have a normal
# systemd service handler).
# <https://pm2.keymetrics.io/docs/usage/quick-start/>. This will require
# the install of PM2 via npm as well.
cd /home/ubuntu
# sudo -u ubuntu npm install @aws-sdk/client-dynamodb @aws-sdk/client-sqs @aws-sdk/client-s3 @aws-sdk/client-sns express multer multer-s3 uuid ip

# Install necessary libraries for our application
sudo -u ubuntu npm install @aws-sdk/client-sqs @aws-sdk/client-sns @aws-sdk/client-s3 @aws-sdk/client-secrets-manager @aws-sdk/client-rds express multer multer-s3 uuid ip mysql2

sudo npm install pm2 -g

# Get your source code (index.html and app.js) on to each EC2 instance
# So we can serve the provided index.html not the default "welcome to Nginx"

# Change URL to your private repo
sudo -u ubuntu git clone git@github.com:illinoistech-itm/mshah132.git

cd mshah132/itmo-544/week9/module-09

sudo cp default /etc/nginx/sites-available/default
sudo ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default #created a symbolic link!

sudo cp index.html /var/www/html/index.html





sudo systemctl enable nginx
sudo systemctl daemon-reload
sudo systemctl restart nginx

# cd command to the directory containing app.js
# WARNING!!! This is the path in my GitHub Repo - yours could be different
# Please adjust accordingly - There be Dragons!
# cd mshah132/itmo-544/week8/module-08/

# Used to auto start the app.js nodejs application at deploy time
sudo pm2 start app.js
