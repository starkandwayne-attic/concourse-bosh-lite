Run Concourse in bosh-lite on AWS
=================================

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
