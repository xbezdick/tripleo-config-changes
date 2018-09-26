tripleo-config-changes
=========

A collection of Ansible playbooks used for applying and validating configuration changes in a TripleO environment.

Requirements
------------

The tests require an undercloud or overcloud to be available for testing the configuration changes against.

Contributing new tests
-----------------------------
We'll take the noop test as example and detail the steps required for adding it.

The noop test only re-runs
the existing overcloud_deploy.sh script without making any configurationg changes.

Tests usually consist of 3 stages:

  - pre: tasks that run before re-running the overcloud deploy (generate new templates,change existing parameters, etc)
  - deploy: re-run the overcloud_deploy.sh script
  - post: validate the changes prepared in the pre step were successfully applied

For adding the noop example test we had to:

  - Create a new directory for your test(noop) under the tasks/ dir:

        mkdir tasks/noop

  - Create the {pre,deploy,post} yml files under tasks/noop directory. These can include either playbooks or tasks. After creating them we can glue them together under tasks/noop/main.yml

        tasks/noop/
         ├── deploy.yml
         ├── main.yml
         ├── post.yml
         └── pre.yml

  - Add a new option for the noop test in plugin.spec

            - title: Apply noop changes
              options:
                  noop:
                      type: Bool
                      help: |
                          Re-run overcloud deploy with no changes
                      default: False

  - Import the tasks/noop/main.yml in the root main.yml based on the conditional option added in the previous step

            - name: Apply noop changes
              import_playbook: tasks/noop/main.yml
              when: test.noop|default(False)

Usage with InfraRed
-----------------------------

tripleo-config-changes comes preinstalled as an InfraRed plugin.

For manual installation:

    # Install plugin
    infrared plugin add https://github.com/rhos-infra/tripleo-config-changes

    # Trigger noop test
    infrared tripleo-config-changes --noop yes

License
-------

Apache 2.0
