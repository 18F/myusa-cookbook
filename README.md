Description
===========

Installs and configures the latest version of [MyUSA](https://github.com/18f/myusa).
Secrets in EC2 are loaded using [Citadel](https://github.com/dlapiduz/citadel),
check out `myusa::ec2_vars` for more details.

Requirements
============

Platform
--------

* Debian, Ubuntu

Usage
=====

Simply include the recipe where you want MyUSA installed.

Required Options
================

- `node['myusa']['secrets']['db_encrypt_key']`: Database encryption key
- `node['myusa']['secrets']['aws_ses_username']`: SES Username
- `node['myusa']['secrets']['aws_ses_password']`: SES Password
- `node['myusa']['secrets']['omniauth_google_app_id']`: Google App ID
- `node['myusa']['secrets']['omniauth_google_secret']`: Google App Secret
- `node['myusa']['secrets']['newrelic_key']`: Newrelic Key
- `node['myusa']['secrets']['secret_key_base']`: Devise secret key base
- `node['myusa']['secrets']['twilio_account_sid']`: Twilio Account SID
- `node['myusa']['secrets']['twilio_auth_token']`: Twilio Token
- `node['myusa']['ssl']['cert']`: Internal SSL certificate file
- `node['myusa']['ssl']['key']`: Internal SSL certificate key
