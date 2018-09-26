---
config:
    plugin_type: test
subparsers:
    tripleo-config-changes:
        description: TripleO config changes tester
        include_groups: ["Ansible options", "Inventory", "Common options", "Answers file"]
        groups:
            - title: Apply noop changes
              options:
                  noop:
                      type: Bool
                      help: |
                          Re-run overcloud deploy with no changes
                      default: False

            - title: Overcloud Options
              options:
                  overcloud-stack:
                      type: Value
                      help: Overrides the overcloud stack name
                      default: "overcloud"
