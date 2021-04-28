# HCI Deployment

## What do you get

An overcloud deployed with network isolation containing:

- 3 Controller
- 3 ComputeHCI

This is a variation of the [standard](../standard) cephadm deploy
but with HCI.

- Use [introspect.sh](introspect.sh) the nodes as tripleo-lab doesn't do that by default
- Use [ironic_capabilities.sh](ironic_capabilities.sh) to set a profile on the HCI nodes for [tripleo_derive_hci_parameters](https://review.opendev.org/#/c/746595)
- Use [deploy.sh](deploy.sh)

The [validate.sh](validate.sh) script does the same things as
the [standard](../standard) validation script but also looks
at the derived parameters.
