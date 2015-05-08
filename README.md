Run Concourse in bosh-lite on AWS
=================================

[Concourse](http://concourse.ci/) is a CI system composed of simple tools and ideas. It can express entire pipelines, integrating with arbitrary resources, or it can be used to execute one-off tasks, either locally or in another CI system.

This project is an alternate to running Concourse via Vagrant directly.

This project makes it easy to deploy Concourse into AWS. And because it internally uses [bosh-lite](http://bosh.io/) for the deployment you will be able to upgrade to each new Concourse release easily.

It also means that your Concourse pipelines can target the bosh-lite and develop/test/deploy BOSH releases.

Dependencies
------------

-	Vagrant
-	Vagrant AWS plugin
-	Ruby 2+
-	Bash
-	An AWS account with API credentials
-	A keypair in AWS us-east-1
-	A security group in AWS us-east-1 with ports 22, 8080 & 25555 open to your host machine

Setup
-----

Setup the following environment variables (or create an `.envrc` if using `direnv`\):

```
export BOSH_AWS_ACCESS_KEY_ID=XXX
export BOSH_AWS_SECRET_ACCESS_KEY=YYY
export BOSH_LITE_NAME=bosh-lite-concourse
export BOSH_LITE_SECURITY_GROUP=bosh
export BOSH_LITE_KEYPAIR=bosh-lite
export BOSH_LITE_PRIVATE_KEY=~/.ssh/bosh-lite.pem
```

Deploy with Vagrant
-------------------

To bootstrap a VM on AWS running bosh-lite, and deploy Concourse inside it:

```
vagrant up --provider=aws && ./setup.sh
```

This will also download the `fly` CLI from your running Concourse into your `$HOME/bin` if it exists, else into the current folder's `bin` folder.

It also saves the target name `bosh-lite`.

You can now access your Concourse using:

```
fly -t bosh-lite
```

Upgrade Concourse
-----------------

To learn about new releases you can Watch the [concourse/concourse repo](https://github.com/concourse/concourse/releases) to get emails for new releases.

To upgrade:

```
bosh upload release https://bosh.io/d/github.com/concourse/concourse
bosh upload release https://bosh.io/d/github.com/cloudfoundry-incubator/garden-linux-release
bosh upload stemcell https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent
bosh deployment concourse.yml
bosh deploy
fly -t bosh-lite sync
```

Destroy Concourse/bosh-lite
---------------------------

Concourse is deployed within bosh-lite which is deployed entirely within a single server on AWS via Vagrant. To destroy everything use the Vagrant tool:

```
vagrant destroy
```

Setup Basic Authentication
--------------------------

To ensure only authorized people can trigger jobs, see private job builds, and other private/destructive activies you can setup a Basic Auth username/password login.

You will need to add some properties to your `concourse.yml` manifest and redeploy.

This project includes some helper scripts:

```
bundle
./encrypt_concourse.sh username password
```

The output is a snippet that can be included in your `concourse.yml` manifest under the `web` job.

For example, the output might be:

```yaml
properties:
  tsa:
    atc:
      username: username
      password: password

  atc:
    basic_auth_username: username
    basic_auth_encrypted_password: $2a$04$oxE/5vLHSbgm0vBGI9JxsuVeFCdFrndpdXvFxD8LuUoVumhtFykGq
    development_mode: false
    publicly_viewable: true
```

Therefore, update the `concourse.yml`'s `web` job to look like:

```yaml
jobs:
  - name: web
    instances: 1
    resource_pool: concourse
    networks:
      - name: concourse
        static_ips: &web-ips [10.244.8.2]
    persistent_disk: 1024 # for consul
    templates:
      - {release: concourse, name: consul-agent}
      - {release: concourse, name: atc}
      - {release: concourse, name: tsa}
    properties:
      tsa:
        atc:
          username: username
          password: password

      atc:
        basic_auth_username: username
        basic_auth_encrypted_password: $2a$04$oxE/5vLHSbgm0vBGI9JxsuVeFCdFrndpdXvFxD8LuUoVumhtFykGq
        development_mode: false
        publicly_viewable: true

        postgresql:
          database: &atc-db atc
          role: &atc-role
            name: atc
            password: dummy-postgres-password

      consul:
        agent:
          mode: server

```

To re-deploy Concourse with the Basic Auth setup:

```
bosh deploy
```

Type "yes" to confirm the changes.
