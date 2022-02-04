---
config:
    plugin_type: test
subparsers:
    tripleo-config-changes:
        description: TripleO config changes tester
        include_groups: ["Ansible options", "Inventory", "Common options", "Answers file"]
        groups:
            - title: Apply overcloud changes
              options:
                  noop:
                      type: Bool
                      help: |
                          Re-run overcloud deploy with no changes
                      default: False
                  overcloud-ssl-enable:
                      type: Bool
                      help: |
                          Enable overcloud ssl
                      default: False
                  tripleo-modify-image:
                      type: Bool
                      help: |
                          Enable tripleo modify image ansible role
                      default: False
                  add-additional-cell:
                      type: Bool
                      help: |
                          Enable multi cell deployment
                      default: False

            - title: Overcloud Options
              options:
                  overcloud-stack:
                      type: Value
                      help: Overrides the overcloud stack name
                      default: "overcloud"

                  openstack-version:
                       type: Value
                       help: |
                           The OpenStack under test version.
                           Numbers are for OSP releases
                           Names are for RDO releases
                       choices:
                           - "6"
                           - "7"
                           - "8"
                           - "9"
                           - "10"
                           - "11"
                           - "12"
                           - "13"
                           - "14"
                           - "15"
                           - "15-trunk"
                           - "16"
                           - "16-trunk"
                           - "16.1"
                           - "16.1-trunk"
                           - "16.2"
                           - "16.2-trunk"
                           - "17"
                           - "17.0"
                           - "17.1"
                           - "17-trunk"
                           - liberty
                           - kilo
                           - liberty
                           - mitaka
                           - newton
                           - ocata
                           - pike
                           - queens
                           - rocky
                           - stein
                           - train
                           - ussuri
                           - victoria
                           - wallaby

            - title: tripleo-modify-image options
              options:
                  tripleo-modify-container:
                      type: Value
                      help: |
                          Name of container without "openstack-" preposition update. For example - 'nova-compute'.
                          Recommended to update one container image at time.
                  tripleo-modify-method:
                      type: Value
                      help: Choose modify option from 'yum-update', 'rpm', 'modify-image'
                      default: "yum-update"
                  tripleo-modify-url:
                      type: Value
                      help: Location for rpm file|Dockerifle which will be uset to build customized container image

